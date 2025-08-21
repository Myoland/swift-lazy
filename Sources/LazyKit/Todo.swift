//
//  Todo.swift
//  swift-lazy
//
//  Created by AFuture on 2025/5/24.
//

/// A function that triggers a `fatalError` with a "[TODO]" prefix.
///
/// This function is useful for marking parts of your code that are not yet implemented.
/// When called, it will cause the program to crash, making it clear that a piece of functionality is missing.
///
/// ```swift
/// func myFeature() {
///     todo("Implement this feature")
/// }
/// ```
///
/// - Parameters:
///   - message: An optional message describing what needs to be done.
///   - file: The file in which the function is called. Defaults to the current file.
///   - line: The line number on which the function is called. Defaults to the current line.
public func todo(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("[TODO]: \(message())", file: file, line: line)
}

/// A function that triggers a `fatalError` with an "UNREACHABLE" message.
///
/// This function is useful for marking code paths that should never be executed.
/// If this function is ever called, it indicates a serious logic error in your code.
///
/// ```swift
/// switch myEnum {
/// case .a:
///     // ...
/// case .b:
///     // ...
/// @unknown default:
///     unreachable()
/// }
/// ```
///
/// - Parameters:
///   - file: The file in which the function is called. Defaults to the current file.
///   - line: The line number on which the function is called. Defaults to the current line.
public func unreachable(file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("UNREACHABLE", file: file, line: line)
}
