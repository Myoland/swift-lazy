//
//  Todo.swift
//  swift-lazy
//
//  Created by AFuture on 2025/5/24.
//

public func todo(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("[TODO]: \(message())", file: file, line: line)
}

public func unreachable(file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("UNREACHABLE", file: file, line: line)
}
