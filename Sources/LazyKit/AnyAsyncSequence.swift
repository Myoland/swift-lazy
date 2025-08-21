//
//  AnyAsyncSequence.swift
//  swift-lazy
//
//  Created by AFuture on 2025/5/25.
//

import SynchronizationKit

/// A type-erasing asynchronous sequence.
///
/// An `AnyAsyncSequence` is a concrete implementation of `AsyncSequence` that wraps another asynchronous sequence,
/// hiding the specific details of the underlying sequence. This is useful when you want to return an asynchronous sequence
/// from a function without exposing the implementation details of the sequence.
public struct AnyAsyncSequence<Element: Sendable>: Sendable, AsyncSequence {
    /// A callback that returns the next element in the sequence.
    public typealias AsyncIteratorNextCallback = () async throws -> Element?

    /// The iterator for an `AnyAsyncSequence`.
    public struct AsyncIterator: AsyncIteratorProtocol, @unchecked Sendable {
        let nextCallback: AsyncIteratorNextCallback

        init(nextCallback: @escaping AsyncIteratorNextCallback) {
            self.nextCallback = nextCallback
        }

        /// Asynchronously advances to the next element and returns it, or `nil` if no next element exists.
        public mutating func next() async throws -> Element? {
            try await self.nextCallback()
        }
    }

    @usableFromInline
    var makeAsyncIteratorCallback: @Sendable () -> AsyncIteratorNextCallback

    /// Creates a new `AnyAsyncSequence` that wraps the given asynchronous sequence.
    /// - Parameter asyncSequence: The asynchronous sequence to wrap.
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

    /// Creates a new `AnyAsyncSequence` that uses the given closure to produce its elements.
    /// - Parameter asyncSequenceMaker: A closure that returns a callback for producing elements.
    public init(
        _ asyncSequenceMaker: @Sendable @escaping () -> AsyncIteratorNextCallback
    ) {
        self.makeAsyncIteratorCallback = asyncSequenceMaker
    }

    /// Creates an asynchronous iterator that produces elements of this sequence.
    public func makeAsyncIterator() -> AsyncIterator {
        .init(nextCallback: self.makeAsyncIteratorCallback())
    }
}

extension AsyncSequence where Self: Sendable, Element: Sendable {
    /// Erases the type of the asynchronous sequence, returning an `AnyAsyncSequence`.
    /// - Returns: An `AnyAsyncSequence` wrapping this sequence.
    public func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
        .init(self)
    }
}
