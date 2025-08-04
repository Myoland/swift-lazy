import SynchronizationKit

extension AsyncSequence where Self: Sendable, Self.Element: Sendable {
    public func cached() -> AsyncCachedSequence<Self> {
        AsyncCachedSequence<Self>(self)
    }
}


public struct AsyncCachedSequence<Base: AsyncSequence & Sendable>: Sendable, AsyncSequence where Base.Element: Sendable {
    public typealias Element = Base.Element

    private let storage: CachedStorage<Base>

    public init(
        _ asyncSequence: Base
    ) {
        self.storage = CachedStorage(producer: asyncSequence)
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(storage: storage)
    }
}

extension AsyncCachedSequence {

    public struct Iterator: AsyncIteratorProtocol {
        fileprivate let storage: CachedStorage<Base>
        fileprivate var idx: Int

        fileprivate init(storage: CachedStorage<Base>) {
            self.storage = storage
            self.idx = 0
        }

        public mutating func next() async throws -> Element? {
            let elem = try await storage.next(idx: idx)
            idx = idx + 1
            return elem
        }
    }
}

extension AsyncCachedSequence {
    fileprivate final class CachedStorage<Producer: AsyncSequence>: Sendable where Producer: Sendable, Producer.Element: Sendable {
        typealias Element = Producer.Element

        let stateMachine: LazyLockedValue<CachedStateMachine<Producer>>

        init(producer: Producer) {
            self.stateMachine = .init(.init(producer: producer))
        }

        func next(idx: Int) async throws -> Element? {
            // Start Task
            let state: CachedStateMachine<Producer>.State? = stateMachine.withLock { stateMachine in
                stateMachine.state.withLock {
                    switch $0 {
                    case .inital(let producer):
                        let task = self.startTask(producer: producer)
                        $0 = .buffering(task: task, buffer: [])
                        return nil
                    default:
                        return $0
                    }
                }
            }

            // Simple Get Stage
            switch state {
            case .buffering(_, let buffer) where idx < buffer.count:
                return buffer[idx]
            case .finished(let result):
                switch result {
                case .success(let buffer) where idx >= 0 && idx < buffer.count:
                    return buffer[idx]
                case .success(_):
                    return nil
                case .failure(let failure):
                    throw failure
                }
            default:
                break
            }

            // wait until the value received
            return try await withCheckedThrowingContinuation { continuation in
                let action = self.stateMachine.withLock { stateMachine in
                    stateMachine.apppendConsumer(idx: idx, continuation: continuation)
                }

                switch action {
                case .none:
                    break
                case .consuming(let result):
                    continuation.resume(with: result)
                }
            }
        }

        func startTask(producer: Producer) -> Task<Void, Never> {
            let task = Task {
                do {
                    for try await element in producer {
                        let action = self.stateMachine.withLock { stateMachine in
                            stateMachine.receiveNewEelment(element)
                        }

                        switch action {
                        case .none:
                            break
                        case .dispatch(let consumers, let result):
                            self.dispatch(consumers: consumers, result: result)
                        }
                    }

                    let action = stateMachine.withLock { $0.onFinished(nil) }
                    switch action {
                    case .none:
                        break
                    case .dispatch(let consumers, let result):
                        self.dispatch(consumers: consumers, result: result)
                    }
                } catch {
                    let action = stateMachine.withLock { $0.onFinished(error) }
                    switch action {
                    case .none:
                        break
                    case .dispatch(let consumers, let result):
                        self.dispatch(consumers: consumers, result: result)
                    }
                }
            }
            return task
        }

        func dispatch(consumers: [Int: [CheckedContinuation<Element?, any Error>]], result: Result<[Element], Error>) {
            switch result {
            case .failure(let error):
                consumers.values.flatMap { $0 }.forEach { $0.resume(throwing: error) }
                break
            case .success(let buffer):
                for (idx, continuations) in consumers {
                    if idx >= 0 && idx < buffer.count {
                        continuations.forEach { $0.resume(returning: buffer[idx]) }
                    } else {
                        continuations.forEach { $0.resume(returning: nil) }
                    }
                }
            }
        }
    }
}

extension AsyncCachedSequence {
    fileprivate final class CachedStateMachine<Producer: AsyncSequence>: Sendable where Producer: Sendable, Producer.Element: Sendable {
        typealias Element = Producer.Element

        enum State {
            case inital(Producer)
            case buffering(task: Task<Void, Never>, buffer: [Element])
            case finished(buffer: Result<[Element], Error>)
        }

        enum NextAction: Sendable {
            case none
            case dispatch([Int: [CheckedContinuation<Element?, any Error>]], Result<[Element], Error>)
        }

        enum FinishedAction: Sendable {
            case none
            case dispatch([Int: [CheckedContinuation<Element?, any Error>]], Result<[Element], Error>)
        }

        enum OnConsumerAppendAction {
            case none
            case consuming(Result<Element?, Error>)
        }

        let state: LazyLockedValue<State>
        let consumers: LazyLockedValue<[Int: [CheckedContinuation<Producer.Element?, any Error>]]>

        init(producer: Producer) {
            self.state = .init(.inital(producer))
            self.consumers = .init([:])
        }

        func receiveNewEelment(_ elem: Element) -> NextAction {
            self.state.withLock { state in
                switch state {
                case .inital(_):
                    return .none
                case .buffering(let task, var buffer):
                    buffer.append(elem)
                    state = .buffering(task: task, buffer: buffer)

                    let consumer = self.popConsumers(size: buffer.count)
                    guard !consumer.values.isEmpty else {
                        return .none
                    }

                    return .dispatch(consumer, .success(buffer))
                case .finished(let result):
                    let consumer = self.popConsumers(size: nil)
                    guard !consumer.values.isEmpty else {
                        return .none
                    }

                    return .dispatch(consumer, result)
                }
            }
        }

        func onFinished(_ error: Error?) -> FinishedAction {
            self.state.withLock { state in

                switch state {
                case .inital(_):
                    preconditionFailure("Invalid State")

                case .buffering(task: _, buffer: let buffer):

                    if let error {
                        state = .finished(buffer: .failure(error))
                    } else {
                        state = .finished(buffer: .success(buffer))
                    }

                    let consumer = popConsumers(size: nil)

                    guard !consumer.values.isEmpty else {
                        return .none
                    }

                    if let error {
                        return .dispatch(consumer, .failure(error))
                    } else {
                        return .dispatch(consumer, .success(buffer))
                    }
                case .finished(buffer: let result):
                    let consumer = popConsumers(size: nil)

                    guard !consumer.values.isEmpty else {
                        return .none
                    }

                    return .dispatch(consumer, result)
                }
            }
        }

        func popConsumers(size: Int?) -> [Int: [CheckedContinuation<Element?, any Error>]] {
            // TODO: [2025/07/04 <Huanan>] filter consumers by size
            return self.consumers.withLock {
                let returning = $0
                $0 = [:] // Set Continuation to nil, or else Swift will throw 'SWIFT TASK CONTINUATION MISUSE'.
                return returning
            }
        }

        // hold the continuation when necessary
        func apppendConsumer(
            idx: Int,
            continuation: CheckedContinuation<Element?, any Error>
        ) -> OnConsumerAppendAction {
            precondition(idx >= 0, "index should greater than or equal to 0.")
            return self.state.withLock { state in
                switch state {
                case .inital(_):
                    return .none
                case .finished(buffer: let result):
                    switch result {
                    case .success(let buffer) where idx < buffer.count:
                        return .consuming(.success(buffer[idx]))
                    case .success(_):
                        // Out of index, return nil.
                        // The iteration should return nil and stop the iteration.
                        return .consuming(.success(nil))
                    case .failure(let error):
                        return .consuming(.failure(error))
                    }
                case .buffering(task: _, buffer: let buffer) where idx >= buffer.count:
                    self.consumers.withLock {
                        if $0[idx] == nil {
                            $0[idx] = []
                        }
                        $0[idx]?.append(continuation)
                    } // Save the consumer
                    return .none
                case .buffering(task: _, buffer: let buffer):
                    return .consuming(.success(buffer[idx]))
                }
            }
        }
    }
}
