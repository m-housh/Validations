//
//  File.swift
//  
//
//  Created by Michael Housh on 8/24/19.
//

import Foundation


extension Validator where T: Validatable {
    
    public static var valid: Validator<T> {
        return ValidatableValidator().validator()
    }
}


fileprivate struct ValidatableValidator<T>: ValidatorType where T: Validatable {
    
    var validatorReadable: String {
        return "validatable"
    }
    
    func validate(_ data: T) throws {
        try data.validate()
    }
    
}
