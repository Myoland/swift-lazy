//
//  AnyEncoder.swift
//  swift-lazy
//
//  Created by AFuture on 2025/5/25.
//

import Foundation

public class AnyEncoder {
        
    public init() {}
    
    public func encode<T>(
        _ value: T,
        userInfo: [CodingUserInfoKey: Any] = [:]
    ) throws -> Any? {
        // [By Huanan On 2025/05/27.] TODO: Using another magic.
        return value
    }
    
    public func encode<T: Encodable>(
        _ value: T,
        userInfo: [CodingUserInfoKey: Any] = [:]
    ) throws -> Any? {
        let encoder = _Encoder(userInfo: userInfo)
        try value.encode(to: encoder)
        return encoder.node
    }
}

private class _Encoder: Encoder {
    var node: Any? = nil
    
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    
    init(
        userInfo: [CodingUserInfoKey: Any] = [:],
        codingPath: [CodingKey] = []
    ) {
        self.userInfo = userInfo
        self.codingPath = codingPath
    }
    
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        .init(_KeyedEncodingContainer<Key>(referencing: self))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        _UnkeyedEncodingContainer(referencing: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
    
    func encoder(for key: CodingKey) -> _Encoder {
        return .init(userInfo: userInfo, codingPath: codingPath + [key])
    }
    
    /// create a new `_ReferencingEncoder` instance at `index` inheriting `userInfo`
    func encoder(at index: CodingKey) -> _Encoder {
        return .init(userInfo: userInfo, codingPath: codingPath + [index])
    }
}

extension _Encoder: SingleValueEncodingContainer {
    
    func encodeNil() throws {
        node = nil
    }
    
    func encode(_ value: Bool) throws {
        node = value
    }
    
    func encode(_ value: String) throws {
        node = value
    }
    
    func encode(_ value: Double) throws {
        node = value
    }
    
    func encode(_ value: Float) throws {
        node = value
    }
    
    func encode(_ value: Int) throws {
        node = value
    }
    
    func encode(_ value: Int8) throws {
        node = value
    }
    
    func encode(_ value: Int16) throws {
        node = value
    }
    
    func encode(_ value: Int32) throws {
        node = value
    }
    
    func encode(_ value: Int64) throws {
        node = value
    }
    
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    func encode(_ value: Int128) throws {
        node = value
    }
    
    func encode(_ value: UInt) throws {
        node = value
    }
    
    func encode(_ value: UInt8) throws {
        node = value
    }
    
    func encode(_ value: UInt16) throws {
        node = value
    }
    
    func encode(_ value: UInt32) throws {
        node = value
    }
    
    func encode(_ value: UInt64) throws {
        node = value
    }
    
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    func encode(_ value: UInt128) throws {
        node = value
    }
    
    func encode<T>(_ value: T) throws where T: Encodable {
        try value.encode(to: self)
    }
}

extension _Encoder {
    var dictionary: [String: Any] {
        get { node as? [String: Any] ?? [:]}
        set { node = newValue }
    }
}

private struct _KeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    
    private let encoder: _Encoder
    
    init(referencing encoder: _Encoder) {
        self.encoder = encoder
    }
    
    var codingPath: [any CodingKey] { return encoder.codingPath }
    
    mutating func encodeNil(forKey key: Key) throws {
        encoder.dictionary[key.stringValue] = nil
    }
    
    func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        let encoder = encoder(for: key)
        try encoder.encode(value)
        self.encoder.dictionary[key.stringValue] = encoder.node
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        encoder(for: key).container(keyedBy: keyType)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
        encoder(for: key).unkeyedContainer()
    }
    
    mutating func superEncoder() -> any Encoder {
        encoder(for: Key(stringValue: "super")!)
    }
    
    mutating func superEncoder(forKey key: Key) -> any Encoder {
        encoder(for: key)
    }
    
    private func encoder(for key: CodingKey) -> _Encoder { return encoder.encoder(for: key) }
    
}

extension _Encoder {
    var collection: [Any] {
        get { node as? [Any] ?? [] }
        set { node = newValue }
    }
}

private struct _UnkeyedEncodingContainer: UnkeyedEncodingContainer {
    private struct _CodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
        
        init(index: Int) {
            self.stringValue = "Index \(index)"
            self.intValue = index
        }
    }
    
    private let encoder: _Encoder
    
    var codingPath: [any CodingKey] {
        encoder.codingPath
    }
    
    var count: Int {
        encoder.collection.count
    }
    
    init(referencing encoder: _Encoder) {
        self.encoder = encoder
    }
    
    func encodeNil() throws {
        encoder.collection.append(Optional<Any>.none as Any)
    }
    
    func encode<T>(_ value: T) throws where T: Encodable {
        let valueEncoder = currentEncoder
        try value.encode(to: valueEncoder)
        
        if isOptional(type: T.self) {
            encoder.collection.append(valueEncoder.node as Any)
        } else {
            encoder.collection.append(valueEncoder.node!)
        }
    }
    
    mutating func superEncoder() -> any Encoder { currentEncoder }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { return currentEncoder.unkeyedContainer() }
    
    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> {
        currentEncoder.container(keyedBy: keyType)
    }
    
    private var currentEncoder: _Encoder { return encoder.encoder(for: _CodingKey(index: count)) }
}

