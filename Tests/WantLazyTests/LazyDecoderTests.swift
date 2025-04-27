import Testing
@testable import WantLazy
import Foundation


@Test("testLazyDecoder")
func testLazyDecoder() async throws {
    let decoder = LazyDecoder()
    
    do {
        let value: Int = try decoder.decode(from: 12 as Decodable, userInfo: [:])
        print(value)
    }
    
    do {
        let value: String = try decoder.decode(from: "foo" as Decodable, userInfo: [:])
        print(value)
    }
    
    do {
        let value: [Int] = try decoder.decode(from: [34, 35] as Decodable, userInfo: [:])
        print(value)
    }
    
    do {
        let value: [String] = try decoder.decode(from: ["Foo", "Bar"] as Decodable, userInfo: [:])
        print(value)
    }
    
    do {
        let value: [String: Int] = try decoder.decode(from: ["Foo": 1, "Bar": 2] as Decodable, userInfo: [:])
        print(value)
    }
    
    do {
        let value: [String: String] = try decoder.decode(from: ["Foo": "Tom", "Bar": "Jerry"] as Decodable, userInfo: [:])
        print(value)
    }
    
    do {
        enum Sex: String, Decodable {
            case boy
            case girl
        }
        struct People: Decodable {
            let name: String
            let age: Int
            let sex: Sex?
        }
        
        let value: People = try decoder.decode(from: ["name": "Tom", "age": 18], userInfo: [:])
        print(value)
    }
    
}
