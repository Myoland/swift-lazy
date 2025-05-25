//
//  Lock.swift
//  swift-lazy
//
//  Created by AFuture on 2025/4/25.
//

#if canImport(NIOConcurrencyHelpers)
import NIOConcurrencyHelpers
#else
import os.lock
#endif

#if canImport(NIOConcurrencyHelpers)
typealias LockPrimitive = NIOLockedValueBox
#else
typealias LockPrimitive = OSAllocatedUnfairLock
#endif

public struct LazyLock<Value>: @unchecked Sendable {
    
    internal let inner: LockPrimitive<Value>
    
    public init(_ value: Value) where Value: Sendable {
#if canImport(NIOConcurrencyHelpers)
        self.inner = .init(value)
#else
        self.inner = .init(initialState: value)
#endif
    }
    
    public init(_ value: Value) {
#if canImport(NIOConcurrencyHelpers)
        self.inner = .init(value)
#else
        self.inner = .init(uncheckedState: value)
#endif
    }
    
    public func withLock<T>(_ mutate: (inout Value) throws -> T) rethrows -> T where T : Sendable {
#if canImport(NIOConcurrencyHelpers)
        try self.inner.withLockedValue(mutate)
#else
        self.inner.withLock(mutate)
#endif
    }
    
    public func withLock<T>(_ mutate: (inout Value) throws -> T) rethrows -> T {
#if canImport(NIOConcurrencyHelpers)
        try self.inner.withLockedValue(mutate)
#else
        self.inner.withLockUnchecked(mutate)
#endif
    }
}
