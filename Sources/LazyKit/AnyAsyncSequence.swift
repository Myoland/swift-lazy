//
//  AnyAsyncSequence.swift
//  swift-lazy
//
//  Created by AFuture on 2025/5/25.
//

import SynchronizationKit

public struct AnyAsyncSequence<Element: Sendable>: Sendable, AsyncSequence {
    public typealias AsyncIteratorNextCallback = () async throws -> Element?

    public struct AsyncIterator: AsyncIteratorProtocol, @unchecked Sendable {
        let nextCallback: AsyncIteratorNextCallback

        init(nextCallback: @escaping AsyncIteratorNextCallback) {
            self.nextCallback = nextCallback
        }

        public mutating func next() async throws -> Element? {
            try await self.nextCallback()
        }
    }

    @usableFromInline
    var makeAsyncIteratorCallback: @Sendable () -> AsyncIteratorNextCallback

    public init<SequenceOfElement>(
        _ asyncSequence: SequenceOfElement
    ) where SequenceOfElement: AsyncSequence & Sendable, SequenceOfElement.Element == Element {
        self.makeAsyncIteratorCallback = {
            var iterator = asyncSequence.makeAsyncIterator()
            return {
                try await iterator.next()
            }
        }
    }

    public init(
        _ asyncSequenceMaker: @Sendable @escaping () -> AsyncIteratorNextCallback
    ) {
        self.makeAsyncIteratorCallback = asyncSequenceMaker
    }

    public func makeAsyncIterator() -> AsyncIterator {
        .init(nextCallback: self.makeAsyncIteratorCallback())
    }
}

extension AsyncSequence where Self: Sendable, Element: Sendable {
    public func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
        .init(self)
    }
}
