//
//  Optional.swift
//  swift-lazy
//
//  Created by AFuture on 2025/5/26.
//

import Foundation


/// A method to test if a type is Optional.
///
/// In Swift, you can not test if a type is Optional using `is`.
/// This function use `_isOptional` from swift.
/// This function can be used in generic functiuon or other similar situation.
///
/// The swift source code located in: https://github.com/swiftlang/swift/blob/1e403ecf5c5a13726e37fc42b494bc4e7944ea3a/stdlib/public/core/Builtin.swift#L825
public func isOptional<T>(type: T.Type) -> Bool {
    return _isOptional(type)
}


