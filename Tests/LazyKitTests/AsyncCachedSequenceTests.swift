import XCTest
import os.lock
@testable import LazyKit

final class AsyncCachedSequenceTests: XCTestCase {
    
    // MARK: - 基本功能测试
    
    func testBasicSequenceIteration() async throws {
        let originalSequence = AsyncStream<Int> { continuation in
            Task {
                for i in 1...5 {
                    continuation.yield(i)
                }
                continuation.finish()
            }
        }
        
        let cachedSequence = AsyncCachedSequence(originalSequence)
        var results: [Int] = []
        
        for try await element in cachedSequence {
            results.append(element)
        }
        
        XCTAssertEqual(results, [1, 2, 3, 4, 5])
    }
    
    func testEmptySequence() async throws {
        let emptySequence = AsyncStream<Int> { continuation in
            continuation.finish()
        }
        
        let cachedSequence = AsyncCachedSequence(emptySequence)
        var results: [Int] = []
        
        for try await element in cachedSequence {
            results.append(element)
        }
        
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - 缓存机制测试
    
    func testCachingMechanism() async throws {
        let callCount = OSAllocatedUnfairLock(initialState: 0)
        let originalSequence = AsyncStream<Int> { continuation in
            Task {
                callCount.withLock { $0 += 1 }
                for i in 1...3 {
                    continuation.yield(i)
                }
                continuation.finish()
            }
        }
        
        let cachedSequence = AsyncCachedSequence(originalSequence)
        
        // 第一次迭代
        var firstResults: [Int] = []
        for try await element in cachedSequence {
            firstResults.append(element)
        }
        
        // 第二次迭代应该使用缓存
        var secondResults: [Int] = []
        for try await element in cachedSequence {
            secondResults.append(element)
        }
        
        XCTAssertEqual(firstResults, [1, 2, 3])
        XCTAssertEqual(secondResults, [1, 2, 3])
        let finalCallCount = callCount.withLock { $0 }
        XCTAssertEqual(finalCallCount, 1, "原始序列应该只被调用一次")
    }
    
    // MARK: - 多迭代器并发测试
    
    func testMultipleIteratorsConcurrent() async throws {
        let originalSequence = AsyncStream<Int> { continuation in
            Task {
                for i in 1...100 {
                    continuation.yield(i)
                    // 模拟一些延迟
                    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
                }
                continuation.finish()
            }
        }
        
        let cachedSequence = AsyncCachedSequence(originalSequence)
        
        try await withThrowingTaskGroup(of: [Int].self) { group in
            // 启动多个并发迭代器
            for _ in 0..<5 {
                group.addTask {
                    var results: [Int] = []
                    for try await element in cachedSequence {
                        results.append(element)
                    }
                    return results
                }
            }
            
            var allResults: [[Int]] = []
            for try await result in group {
                allResults.append(result)
            }
            
            // 所有迭代器应该得到相同的结果
            let expected = Array(1...100)
            for result in allResults {
                XCTAssertEqual(result, expected)
            }
        }
    }
    
    func testMultipleIteratorsInterleavedAccess() async throws {
        let originalSequence = AsyncStream<Int> { continuation in
            Task {
                for i in 1...10 {
                    continuation.yield(i)
                }
                continuation.finish()
            }
        }
        
        let cachedSequence = AsyncCachedSequence(originalSequence)
        
        var iterator1 = cachedSequence.makeAsyncIterator()
        var iterator2 = cachedSequence.makeAsyncIterator()
        
        // 交替访问两个迭代器
        let elem1_1 = try await iterator1.next()
        let elem2_1 = try await iterator2.next()
        let elem1_2 = try await iterator1.next()
        let elem2_2 = try await iterator2.next()
        
        XCTAssertEqual(elem1_1, 1)
        XCTAssertEqual(elem2_1, 1)
        XCTAssertEqual(elem1_2, 2)
        XCTAssertEqual(elem2_2, 2)
    }
    
    // MARK: - 错误处理测试
    
    func testSequenceWithError() async throws {
        struct TestError: Error, Equatable {}
        
        let errorSequence = AsyncThrowingStream<Int, Error> { continuation in
            Task {
                continuation.yield(1)
                continuation.yield(2)
                continuation.finish(throwing: TestError())
            }
        }
        
        let cachedSequence = AsyncCachedSequence(errorSequence)
        
        do {
            var results: [Int] = []
            for try await element in cachedSequence {
                results.append(element)
            }
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }
    
    func testErrorIsCachedAndRethrown() async throws {
        struct TestError: Error, Equatable {}
        let iterationCount = OSAllocatedUnfairLock(initialState: 0)
        
        let errorSequence = AsyncThrowingStream<Int, Error> { continuation in
            Task {
                iterationCount.withLock { $0 += 1 }
                continuation.yield(1)
                continuation.yield(2)
                continuation.finish(throwing: TestError())
            }
        }
        
        let cachedSequence = AsyncCachedSequence(errorSequence)
        
        // 第一次迭代
        do {
            for try await _ in cachedSequence {}
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(error is TestError)
        }
        
        // 第二次迭代应该重用缓存的错误
        do {
            for try await _ in cachedSequence {}
            XCTFail("应该抛出错误")
        } catch {
            XCTAssertTrue(error is TestError)
        }
        
        let finalCount = iterationCount.withLock { $0 }
        XCTAssertEqual(finalCount, 1, "原始序列应该只被执行一次")
    }
    
    // MARK: - 边界情况测试
    
    func testSingleElementSequence() async throws {
        let singleElementSequence = AsyncStream<String> { continuation in
            continuation.yield("single")
            continuation.finish()
        }
        
        let cachedSequence = AsyncCachedSequence(singleElementSequence)
        var results: [String] = []
        
        for try await element in cachedSequence {
            results.append(element)
        }
        
        XCTAssertEqual(results, ["single"])
    }
    
    func testIteratorAfterSequenceCompleted() async throws {
        let originalSequence = AsyncStream<Int> { continuation in
            Task {
                for i in 1...3 {
                    continuation.yield(i)
                }
                continuation.finish()
            }
        }
        
        let cachedSequence = AsyncCachedSequence(originalSequence)
        
        // 完全消费序列
        var firstResults: [Int] = []
        for try await element in cachedSequence {
            firstResults.append(element)
        }
        
        // 创建新迭代器应该立即从缓存返回所有元素
        var iterator = cachedSequence.makeAsyncIterator()
        var secondResults: [Int] = []
        
        while let element = try await iterator.next() {
            secondResults.append(element)
        }
        
        XCTAssertEqual(firstResults, [1, 2, 3])
        XCTAssertEqual(secondResults, [1, 2, 3])
    }
    
    // MARK: - 性能测试
    
    func testLargeSequencePerformance() async throws {
        let largeSequence = AsyncStream<Int> { continuation in
            Task {
                for i in 1...10000 {
                    continuation.yield(i)
                }
                continuation.finish()
            }
        }
        
        let cachedSequence = AsyncCachedSequence(largeSequence)
        
        // 测量第一次迭代时间
        let startTime1 = mach_absolute_time()
        var count1 = 0
        for try await _ in cachedSequence {
            count1 += 1
        }
        let duration1 = mach_absolute_time() - startTime1
        
        // 测量第二次迭代时间（应该更快，因为使用缓存）
        let startTime2 = mach_absolute_time()
        var count2 = 0
        for try await _ in cachedSequence {
            count2 += 1
        }
        let duration2 = mach_absolute_time() - startTime2
        
        XCTAssertEqual(count1, 10000)
        XCTAssertEqual(count2, 10000)
        
        // 缓存访问应该显著更快
        XCTAssert(duration2 < duration1, "缓存访问应该比首次访问快至少50%")
    }
    
    // MARK: - 特殊场景测试
    
    func testIteratorResetBehavior() async throws {
        let originalSequence = AsyncStream<Int> { continuation in
            Task {
                for i in 1...5 {
                    continuation.yield(i)
                }
                continuation.finish()
            }
        }
        
        let cachedSequence = AsyncCachedSequence(originalSequence)
        var iterator = cachedSequence.makeAsyncIterator()
        
        // 读取前3个元素
        let elem1 = try await iterator.next()
        let elem2 = try await iterator.next()
        let elem3 = try await iterator.next()
        
        XCTAssertEqual(elem1, 1)
        XCTAssertEqual(elem2, 2)
        XCTAssertEqual(elem3, 3)
        
        // 创建新迭代器，应该从头开始
        var newIterator = cachedSequence.makeAsyncIterator()
        let newElem1 = try await newIterator.next()
        let newElem2 = try await newIterator.next()
        
        XCTAssertEqual(newElem1, 1)
        XCTAssertEqual(newElem2, 2)
        
        // 原迭代器继续从第4个元素开始
        let elem4 = try await iterator.next()
        let elem5 = try await iterator.next()
        let elemNil = try await iterator.next()
        
        XCTAssertEqual(elem4, 4)
        XCTAssertEqual(elem5, 5)
        XCTAssertNil(elemNil)
    }
} 
