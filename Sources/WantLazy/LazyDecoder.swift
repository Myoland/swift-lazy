//
//  DicDecoder.swift
//  swift-lazy
//
//  Created by AFuture on 2025/4/26.
//

import Foundation

/// https://github.com/swiftlang/swift-foundation/blob/main/Sources/FoundationEssentials/JSON/JSONDecoder.swift
public class LazyDecoder {
    
    init() {}
    
    public func decode<T>(_ type: T.Type = T.self,
                          from dictionary: Any,
                          userInfo: [CodingUserInfoKey : Any]) throws -> T where T: Decodable {
        
        let decoder = _Decoder(referencing: dictionary, userInfo: userInfo)
        let container = try decoder.singleValueContainer()
        return try container.decode(type)
    }
}

private struct _Decoder: Decoder {
    
    var codingPath: [any CodingKey]
    
    var userInfo: [CodingUserInfoKey : Any]
    
    fileprivate let refer: Any?
    
    init(referencing refer: Any?, userInfo: [CodingUserInfoKey: Any], codingPath: [CodingKey] = []) {
        self.refer = refer
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let mapping = refer as? [String: any Decodable] else {
            fatalError()
        }
        return .init(_KeyedDecodingContainer<Key>(decoder: self, wrapping: mapping))
    }
    
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        guard let sequence = refer as? [any Decodable] else {
            fatalError()
        }
        return _UnkeyedDecodingContainer(decoder: self, wrapping: sequence)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer { return self }
    
    func decoder(referencing node: any Decodable, `as` key: CodingKey) -> _Decoder {
        return .init(referencing: node, userInfo: userInfo, codingPath: codingPath + [key])
    }
}

extension _Decoder: SingleValueDecodingContainer {
    
    func decodeNil() -> Bool { self.refer == nil }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        guard let value = self.refer as? Bool else {
            throw DecodingError.typeMismatch(Bool.self, .init(codingPath: codingPath, debugDescription: "Expect `Bool` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: String.Type) throws -> String {
        guard let value = self.refer as? String else {
            throw DecodingError.typeMismatch(String.self, .init(codingPath: codingPath, debugDescription: "Expect `String` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        guard let value = self.refer as? Double else {
            throw DecodingError.typeMismatch(Double.self, .init(codingPath: codingPath, debugDescription: "Expect `Double` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        guard let value = self.refer as? Float else {
            throw DecodingError.typeMismatch(Float.self, .init(codingPath: codingPath, debugDescription: "Expect `Float` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        guard let value = self.refer as? Int else {
            throw DecodingError.typeMismatch(Int.self, .init(codingPath: codingPath, debugDescription: "Expect `Int` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        guard let value = self.refer as? Int8 else {
            throw DecodingError.typeMismatch(Int8.self, .init(codingPath: codingPath, debugDescription: "Expect `Int8` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        guard let value = self.refer as? Int16 else {
            throw DecodingError.typeMismatch(Int16.self, .init(codingPath: codingPath, debugDescription: "Expect `Int16` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        guard let value = self.refer as? Int32 else {
            throw DecodingError.typeMismatch(Int32.self, .init(codingPath: codingPath, debugDescription: "Expect `Int32` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        guard let value = self.refer as? Int64 else {
            throw DecodingError.typeMismatch(Int64.self, .init(codingPath: codingPath, debugDescription: "Expect `Int64` but found `\(self.refer)`"))
        }
        return value
    }
    
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    func decode(_ type: Int128.Type) throws -> Int128 {
        guard let value = self.refer as? Int128 else {
            throw DecodingError.typeMismatch(Int128.self, .init(codingPath: codingPath, debugDescription: "Expect `Int128` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        guard let value = self.refer as? UInt else {
            throw DecodingError.typeMismatch(UInt.self, .init(codingPath: codingPath, debugDescription: "Expect `UInt` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard let value = self.refer as? UInt8 else {
            throw DecodingError.typeMismatch(UInt8.self, .init(codingPath: codingPath, debugDescription: "Expect `UInt8` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard let value = self.refer as? UInt16 else {
            throw DecodingError.typeMismatch(UInt16.self, .init(codingPath: codingPath, debugDescription: "Expect `UInt16` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard let value = self.refer as? UInt32 else {
            throw DecodingError.typeMismatch(UInt32.self, .init(codingPath: codingPath, debugDescription: "Expect `UInt32` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard let value = self.refer as? UInt64 else {
            throw DecodingError.typeMismatch(UInt64.self, .init(codingPath: codingPath, debugDescription: "Expect `UInt64` but found `\(self.refer)`"))
        }
        return value
    }
    
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    func decode(_ type: UInt128.Type) throws -> UInt128 {
        guard let value = self.refer as? UInt128 else {
            throw DecodingError.typeMismatch(UInt128.self, .init(codingPath: codingPath, debugDescription: "Expect `UInt128` but found `\(self.refer)`"))
        }
        return value
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable { try type.init(from: self) }
}

private struct _KeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    
    private let decoder: _Decoder
    private let mapping: [String: any Decodable]
    
    init(decoder: _Decoder, wrapping mapping: [String: any Decodable]) {
        self.decoder = decoder
        self.mapping = mapping
    }
    
    // MARK: - Swift.KeyedDecodingContainerProtocol Methods
    
    var codingPath: [CodingKey] { return decoder.codingPath }
    var allKeys: [Key] { return mapping.keys.compactMap { Key(stringValue: $0) } }
    
    func contains(_ key: Key) -> Bool { return mapping[key.stringValue] != nil }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        return try decoder(for: key).decodeNil()
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        return try decoder(for: key).decode(type)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                    forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        return try decoder(for: key).container(keyedBy: type)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return try decoder(for: key).unkeyedContainer()
    }
    
    func superDecoder() throws -> Decoder { try decoder(for: Key(stringValue: "super")!) }
    func superDecoder(forKey key: Key) throws -> Decoder { try decoder(for: key) }

    private func decoder(for key: CodingKey) throws -> _Decoder {
        guard let value = mapping[key.stringValue] else {
            fatalError()
        }
        
        return decoder.decoder(referencing: value, as: key)
    }
}


private struct _UnkeyedDecodingContainer: UnkeyedDecodingContainer {
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
    
    
    private let decoder: _Decoder
    private let sequence: [any Decodable]
    
    init(decoder: _Decoder, wrapping sequence: [any Decodable]) {
        self.decoder = decoder
        self.sequence = sequence
        self.currentIndex = 0
    }
    
    // MARK: - Swift.UnkeyedDecodingContainer Methods
    
    var codingPath: [CodingKey] { return decoder.codingPath }
    var count: Int? { return sequence.count }
    var isAtEnd: Bool { return currentIndex >= sequence.count }
    var currentIndex: Int
    
    mutating func decodeNil() throws -> Bool {
        try throwErrorIfAtEnd(Any?.self)
        return try currentDecoder { $0.decodeNil() }
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        return try currentDecoder { try $0.decode(type) }
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        return try currentDecoder { try $0.container(keyedBy: type) }
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try currentDecoder { try $0.unkeyedContainer() }
    }
    
    mutating func superDecoder() throws -> Decoder { return try currentDecoder { $0 } }
    
    // MARK: -
    
    private var currentKey: CodingKey { return _CodingKey(index: currentIndex) }
    private var currentNode: any Decodable { return sequence[currentIndex] }
    
    private func throwErrorIfAtEnd<T>(_ type: T.Type) throws {
        if isAtEnd { throw DecodingError.valueNotFound(type, .init(codingPath: codingPath + [currentKey], debugDescription: "Unkeyed container is at end.")) }
    }
    
    private mutating func currentDecoder<T>(closure: (_Decoder) throws -> T) throws -> T {
        try throwErrorIfAtEnd(T.self)
        let decoded: T = try closure(decoder.decoder(referencing: currentNode, as: currentKey))
        currentIndex += 1
        return decoded
    }
}
