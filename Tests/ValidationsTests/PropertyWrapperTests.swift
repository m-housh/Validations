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
        var val = TestWrapped(nonEmpty: "12345")
        XCTAssert(val.$nonEmpty.isValid)
        XCTAssertEqual(val.nonEmpty, "12345")
        
        val.nonEmpty = ""
        XCTAssertFalse(val.$nonEmpty.isValid)
        val.nonEmpty = nil
        XCTAssertFalse(val.$nonEmpty.isValid)
        
        val.two = "not empty"
        XCTAssert(val.$two.isValid)
        val.two = nil
        XCTAssertFalse(val.$two.isValid)
        
        XCTAssert(val.three == "")
        val.three = "foo"
        XCTAssert(val.$three.isValid)
        val.three = "not empty"
        XCTAssertFalse(val.$three.isValid)

    }
    
    func testErrors() {
        var val = TestWrapped()
        val.two = nil
        _ = val.two
        
        XCTAssertNotNil(val.$two.error)
        print(val.$two.error ?? "no error")
    }
    
}


struct TestWrapped {
    
    static var validator: Validator<String?> {
        return !.nil && !.empty
    }
        
    @Validate(TestWrapped.validator) var nonEmpty: String? = nil
    
    /// Two doc-string.
    @Validate(!.nil && !.empty)
    var two: String? = nil
    
    @Validate(default: "", !.empty && .count(1..<5))
    var three: String = ""
    
    
}
