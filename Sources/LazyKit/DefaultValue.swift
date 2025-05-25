//
//  Default.swift
//  swift-lazy
//
//  Created by AFuture on 2025/4/29.
//
// MARK: - DefaultValue

/// Protocol that defines a type that provides a default value.
/// Used with the `Default` property wrapper to provide default values for Codable properties.
public protocol DefaultValue {
    associatedtype Value
    static var defaultValue: Value { get }
}

// MARK: - Default

/// A property wrapper that provides a default value for Codable properties.
/// When decoding, if the key is missing or the value is null, the default value will be used.
@propertyWrapper
public struct Default<T: DefaultValue> {
    public var wrappedValue: T.Value
    
    public init(wrappedValue: T.Value = T.defaultValue) {
        self.wrappedValue = wrappedValue
    }
}

// MARK: Equatable

extension Default: Equatable where T.Value: Equatable {
    public static func == (lhs: Default<T>, rhs: Default<T>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

// MARK: Hashable

extension Default: Hashable where T.Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

// MARK: Decodable

extension Default: Decodable where T.Value: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = (try? container.decode(T.Value.self)) ?? T.defaultValue
    }
}

// MARK: Encodable

extension Default: Encodable where T.Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

/// Extension to provide automatic handling of `Default` property wrapper in keyed decoding containers.
public extension KeyedDecodingContainer {
    /// Overrides the default `decode(_:forKey:)` behavior for `Default` property wrappers.
    /// When a key is missing or contains a null value, this returns an instance with the default value.
    func decode<T>(_ type: Default<T>.Type, forKey key: Key) throws -> Default<T> where T: DefaultValue, T.Value: Decodable {
        try decodeIfPresent(type, forKey: key) ?? Default<T>()
    }
}
