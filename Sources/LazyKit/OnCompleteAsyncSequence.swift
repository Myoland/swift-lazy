//
//  OnCompleteAsyncSequence.swift
//  swift-lazy
//
//  Created by AFuture on 2025/6/8.
//

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct OnCompleteAsyncSequence<Element>: Sendable, AsyncSequence {
    public typealias AsyncIteratorNextCallback = () async throws -> Element?
    public typealias AsyncOnCompleteCallback = @Sendable () async throws -> Void
    
    public struct AsyncIterator: AsyncIteratorProtocol {
        let nextCallback: AsyncIteratorNextCallback
        let onComplete: AsyncOnCompleteCallback
        
        init(
            nextCallback: @escaping AsyncIteratorNextCallback,
            onComplete: @escaping AsyncOnCompleteCallback
        ) {
            self.nextCallback = nextCallback
            self.onComplete = onComplete
        }
        
        public mutating func next() async throws -> Element? {
            let elem = try await self.nextCallback()
            if elem == nil {
                try await onComplete()
            }
            return elem
        }
    }
    
    @usableFromInline
    let makeAsyncIteratorCallback: @Sendable () -> AsyncIteratorNextCallback
    
    @usableFromInline
    let onComplete: AsyncOnCompleteCallback
    
    public init<SequenceOfElement>(
        _ asyncSequence: SequenceOfElement,
        onComplete: @escaping AsyncOnCompleteCallback
    ) where SequenceOfElement: AsyncSequence & Sendable, SequenceOfElement.Element == Element {
        self.onComplete = onComplete
        self.makeAsyncIteratorCallback = {
            var iterator = asyncSequence.makeAsyncIterator()
            return {
                try await iterator.next()
            }
        }
    }
    
    public init(
        _ asyncSequenceMaker: @Sendable @escaping () -> AsyncIteratorNextCallback,
        onComplete: @escaping AsyncOnCompleteCallback
    ) {
        self.makeAsyncIteratorCallback = asyncSequenceMaker
        self.onComplete = onComplete
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        .init(nextCallback: self.makeAsyncIteratorCallback(), onComplete: self.onComplete)
    }
}
