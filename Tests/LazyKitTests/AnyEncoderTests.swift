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
    print(encoded as Any)
}
