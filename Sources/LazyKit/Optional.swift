//
//  Optional.swift
//  swift-lazy
//
//  Created by AFuture on 2025/5/26.
//

import Foundation


/// Checks if a given type is an `Optional`.
///
/// In Swift, you cannot directly check if a type is an `Optional` using the `is` operator.
/// This function uses the internal `_isOptional` function from the Swift standard library to perform this check.
/// It is useful in generic contexts where you need to determine if a type is optional.
///
/// The Swift source code for `_isOptional` can be found here:
/// [swift/stdlib/public/core/Builtin.swift](https://github.com/swiftlang/swift/blob/1e403ecf5c5a13726e37fc42b494bc4e7944ea3a/stdlib/public/core/Builtin.swift#L825)
///
/// - Parameter type: The type to check.
/// - Returns: `true` if the type is an `Optional`, otherwise `false`.
public func isOptional<T>(type: T.Type) -> Bool {
    return _isOptional(type)
}
