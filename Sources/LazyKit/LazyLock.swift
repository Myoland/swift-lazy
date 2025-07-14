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


public struct LazyLockedValue<Value>: @unchecked Sendable {

#if canImport(NIOConcurrencyHelpers)
    typealias LockPrimitive = NIOLockedValueBox
#else
    typealias LockPrimitive = OSAllocatedUnfairLock
#endif

    
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
    
    public func withLock<T>(_ mutate: @Sendable (inout Value) throws -> T) rethrows -> T where T : Sendable {
#if canImport(NIOConcurrencyHelpers)
        try self.inner.withLockedValue(mutate)
#else
        try self.inner.withLock(mutate)
#endif
    }
    
    public func withLock<T>(_ mutate: (inout Value) throws -> T) rethrows -> T {
#if canImport(NIOConcurrencyHelpers)
        try self.inner.withLockedValue(mutate)
#else
        try self.inner.withLockUnchecked(mutate)
#endif
    }
}


public struct LazyLock: @unchecked Sendable {
#if canImport(NIOConcurrencyHelpers)
    typealias LockPrimitive = NIOLock
#else
    typealias LockPrimitive = OSAllocatedUnfairLock<()>
#endif
    
    internal let inner: LockPrimitive

    public init() {
#if canImport(NIOConcurrencyHelpers)
        self.inner = .init()
#else
        self.inner = .init()
#endif
    }
    
    public func lock() {
        self.inner.lock()
    }
    
    public func unlock() {
        self.inner.unlock()
    }
}
