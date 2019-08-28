//
//  File.swift
//  
//
//  Created by Michael Housh on 8/23/19.
//

import Validations
import Combine
import XCTest


class PropertyWrapperTests: XCTestCase {
    
    func testWrappedProperty() {
        let val = TestWrapped(nonEmpty: "12345")
        XCTAssert(val.$nonEmpty.isValid)
        XCTAssertEqual(val.nonEmpty, "12345")
        
        val.nonEmpty = ""
        XCTAssertFalse(val.$nonEmpty.isValid)
        val.nonEmpty = nil
        XCTAssertFalse(val.$nonEmpty.isValid)
        
        XCTAssertFalse(val.$two.isValid)
        val.two = "not empty"
        XCTAssert(val.$two.isValid)
        
        XCTAssertFalse(val.$three.isValid)
        XCTAssert(val.three == "")
        print()
        print(val.$three.error!)
        print()
        val.three = "foo"
        XCTAssert(val.$three.isValid)
        val.three = "not empty"
        XCTAssertFalse(val.$three.isValid)

    }
    
    func testErrors() {
        let val = TestWrapped()
        val.two = nil
        _ = val.two
        
        XCTAssertNotNil(val.$two.error)
        print(val.$two.error ?? "no error")
    }
    
    
    func testValidatableObject() {
        let val = TestWrapped()
        XCTAssert(val.$pet.isValid)
        
        val.pet.name = ""
        XCTAssertFalse(val.$pet.isValid)
    }
    
    func testValidateOr() {
        let val = TestWrapped()
        XCTAssertFalse(val.$fooBar.isValid)
        XCTAssertEqual(val.fooBar, "foo-bar")
        
        val.fooBar = "baz-bing"
        XCTAssert(val.$fooBar.isValid)
        XCTAssertEqual(val.fooBar, "baz-bing")
        
        val.fooBar = ""
        XCTAssertEqual(val.fooBar, "foo-bar")
    }
    
    func testValidteOrWithValidatable() {
        let val = TestWrapped()
        XCTAssertEqual(val.petOrDefault.name, TestWrapped.DefaultPet.name)
        
        val.petOrDefault.name = "sparky"
        val.petOrDefault.age = 3
        
        print()
        print(val.petOrDefault.name)
        print()
        //print(val.$petOrDefault.error)
        //XCTAssert(val.$petOrDefault.isValid)
    }
    
    @available(macOS 10.15, iOS 13, *)
    func testPublisher() {
        let publisher = PassthroughSubject<String, Never>()
       
    }
    
}


struct TestWrapped {
    
    static var validator: Validator<String?> {
        return !.nil && !.empty
    }
    
    static var DefaultPet = Pet(name: "Coco Chanelle", age: 4)
    
    @Validate(using: TestWrapped.validator) var nonEmpty: String? = nil
    
    /// Two doc-string.
    @Validate(!.nil && !.empty) var two: String? = nil
    
    @Validate(!.empty && .count(1..<5)) var three: String = ""
    
    @Validate var pet: Pet = Pet(name: "barky", age: 5)
    
    @ValidateOr(!.empty && .count(1...), with: "foo-bar") var fooBar: String = ""
    
    @ValidateOr(with: TestWrapped.DefaultPet) var petOrDefault: Pet = Pet(name: "", age: 0)
}



@propertyWrapper
@available(macOS 15, iOS 13, *)
struct CombineValidaionWrapper<V> {
    
    public var wrappedValue: V
    
    private let publisher: Just<Validator<V>>
    private let subject: PassthroughSubject<V, Never>
    
    
    public init(wrappedValue: V, _ validator: Validator<V>) {
        self.publisher = Just(validator)
        self.subject = PassthroughSubject<V, Never>()
        self.wrappedValue = wrappedValue
    }
    
}
