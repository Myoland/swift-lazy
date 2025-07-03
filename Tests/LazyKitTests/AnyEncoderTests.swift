//
//  AnyEncoderTests.swift
//  swift-lazy
//
//  Created by AFuture on 2025/5/25.
//

import Foundation
import Testing

@testable import LazyKit

private struct Custom: Encodable {
    let intValue: Int?
    let stringValue: String?
    let dict: [String: String]?
}

@Test("testAnyEncoder")
func testAnyEncoder() async throws {

    // let value = ["aa": Custom(intValue: 1, stringValue: "baz", dict: ["foo":"bar"])]
    let value = [
        [Custom(intValue: 1, stringValue: nil, dict: nil), Custom(intValue: nil, stringValue: "foo", dict: nil), nil],
        [Custom(intValue: 2, stringValue: nil, dict: nil), Custom(intValue: nil, stringValue: "bar", dict: nil)]
    ]

    let encoder = AnyEncoder()
    let encoded = try encoder.encode(value)
}



@Test("testDecodeEmpty")
func testDecodeEmpty() throws {
    struct Model: Codable, Sendable {
        let str: String
        let int: Int
        let bool: Bool
        let array: [String]
        let dict: [String: String]
        let emptyStr: String?
        let emptyInt: Int?
        let emptyBool: Bool?
        let emptyArray: [String]?
        let emptyDict: [String: String]?
    }

    let json = """
    {"str":"str","int":1,"bool":true,"array":[],"dict":{},"emptyStr":null,"emptyInt":null,"emptyBool":null,"emptyArray":null,"emptyDict":null}
    """

    let decoder = JSONDecoder()
    let model = try decoder.decode(Model.self, from: json.data(using: .utf8)!)

    let encoder = AnyEncoder()
    let encoded = try encoder.encode(model) as? [String: Any]
    #expect(encoded?.keys.contains("array") == true)
    #expect(encoded?.keys.contains("dict") == true)
    #expect(encoded?.keys.contains("emptyArray") == false)
    #expect(encoded?.keys.contains("emptyDict") == false)
}
