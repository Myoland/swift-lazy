import Testing
@testable import WantLazy
import Foundation

@Test("testLazyDecoder")
func testLazyDecoder() async throws {
    let decoder = LazyDecoder()
    
    // Test primitive types
    do {
        let value: Int = try decoder.decode(from: 12 as Decodable, userInfo: [:])
        #expect(value == 12)
    }
    
    do {
        let value: String = try decoder.decode(from: "foo" as Decodable, userInfo: [:])
        #expect(value == "foo")
    }
    
    // Test arrays
    do {
        let value: [Int] = try decoder.decode(from: [34, 35] as Decodable, userInfo: [:])
        #expect(value == [34, 35])
    }
    
    do {
        let value: [String] = try decoder.decode(from: ["Foo", "Bar"] as Decodable, userInfo: [:])
        #expect(value == ["Foo", "Bar"])
    }
    
    // Test simple dictionaries
    do {
        let value: [String: Int] = try decoder.decode(from: ["Foo": 1, "Bar": 2] as Decodable, userInfo: [:])
        #expect(value == ["Foo": 1, "Bar": 2])
    }
    
    do {
        let value: [String: String] = try decoder.decode(from: ["Foo": "Tom", "Bar": "Jerry"] as Decodable, userInfo: [:])
        #expect(value == ["Foo": "Tom", "Bar": "Jerry"])
    }
    
    // Test nested dictionaries
    do {
        struct Nested: Decodable {
            let outer: [String: [String: Int]]
        }
        
        let value: Nested = try decoder.decode(
            from: ["outer": ["inner": ["a": 1, "b": 2]]],
            userInfo: [:]
        )
        #expect(value.outer["inner"]?["a"] == 1)
        #expect(value.outer["inner"]?["b"] == 2)
    }
    
    // Test different numeric types
    do {
        struct Numbers: Decodable {
            let int8: Int8
            let int16: Int16
            let int32: Int32
            let int64: Int64
            let uint: UInt
            let double: Double
            let float: Float
        }
        
        let value: Numbers = try decoder.decode(
            from: [
                "int8": Int8(8),
                "int16": Int16(16),
                "int32": Int32(32),
                "int64": Int64(64),
                "uint": UInt(100),
                "double": Double(3.14),
                "float": Float(2.71)
            ],
            userInfo: [:]
        )
        #expect(value.int8 == 8)
        #expect(value.int16 == 16)
        #expect(value.int32 == 32)
        #expect(value.int64 == 64)
        #expect(value.uint == 100)
        #expect(value.double == 3.14)
        #expect(value.float == 2.71)
    }
    
    // Test complex nested structure
    do {
        enum Status: String, Decodable {
            case active = "Active"
            case inactive = "Inactive"
        }
        
        enum Sex: Int, Decodable {
            case boy = 1
            case girl = 2
        }
        
        struct Address: Decodable {
            let street: String
            let city: String
            let zip: Int
        }
        
        struct Company: Decodable {
            let name: String
            let employees: [Employee]
        }
        
        struct Employee: Decodable {
            let id: Int
            let name: String
            let status: Status
            let sex: Sex
            let address: Address?
            let skills: [String]
        }
        
        let value: Company = try decoder.decode(
            from: [
                "name": "Tech Corp",
                "employees": [
                    [
                        "id": 1,
                        "name": "John",
                        "status": "Active",
                        "sex": 1,
                        "address": [
                            "street": "123 Main St",
                            "city": "Tech City",
                            "zip": 12345
                        ],
                        "skills": ["Swift", "iOS"]
                    ],
                    [
                        "id": 2,
                        "name": "Jane",
                        "status": "Inactive",
                        "sex": 2,
                        "skills": ["Python", "ML"]
                    ]
                ]
            ],
            userInfo: [:]
        )
        
        #expect(value.name == "Tech Corp")
        #expect(value.employees.count == 2)
        #expect(value.employees[0].name == "John")
        #expect(value.employees[0].status == .active)
        #expect(value.employees[0].sex == .boy)
        #expect(value.employees[0].address?.street == "123 Main St")
        #expect(value.employees[0].skills == ["Swift", "iOS"])
        #expect(value.employees[1].name == "Jane")
        #expect(value.employees[1].status == .inactive)
        #expect(value.employees[1].sex == .girl)
        #expect(value.employees[1].address == nil)
        #expect(value.employees[1].skills == ["Python", "ML"])
    }
    
    do {
        struct Person: Decodable {
            let name: String
            let age: Int
        }
        
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(
                from: ["name": "Tom"],
                userInfo: [:]
            ) as Person
        }
        
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(
                from: ["name": "Tom", "age": "18"],
                userInfo: [:]
            ) as Person
        }
    }
}
