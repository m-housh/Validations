//
//  Validate.swift
//  
//
//  Created by Michael Housh on 8/23/19.
//

import Foundation


/**
 # Validate
 
 A property wrapper that allows values to be validated.
 
 ## Usage
 ------
 
 ``` swift
 struct MyObject {
 
    @Validate(!.empty && .count(1..<5)) var lessThanFive: String = ""
 
 }
 
 let myObject = MyObject()
 myObject.$lessThanFive.isValid
 // false
 
 myObject.lessThanFive == ""
 // true
 
 print(myObject.$lessThanFive.error!)
 // ⚠️ [AndValidatorError.validationFailed: data is empty and data is less than required minimum of 1 character]
 
 myObject.lessThanFive = "123"
 myObject.$lessThanFive.isValid
 // true
 
 myObject.lessThanFive = "more than five"
 myObject.$lessThanFive.isValid
 // false
 
 myObject.lessThanFive == "more than five"
 // true
 ```
 
 
 */
@propertyWrapper
public final class Validate<Value> {
    
    private var value: Value? = nil
    
    private var validator: Validator<Value>
    
    //private var useDefaultValue: Bool = false
    
    //private var defaultValue: Value? = nil
    
    public var error: String? = nil
    
    public var wrappedValue: Value {
        get {
            guard let value = self.value else {
                fatalError("no value set")
            }
            //return useDefaultValue ? defaultValue! : value
            return value
        }
        set {
            value = newValue
            validate()
        }
    }
    
    public func validate() {
        do {
            try validator.validate(wrappedValue)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    public var isValid: Bool {
        validate()
        return error == nil
    }
    
    public var projectedValue: Validate<Value> {
        return self
    }
    
   
    
    public init(wrappedValue: Value, using validator: Validator<Value>) {
           self.validator = validator
           self.wrappedValue = wrappedValue
           //self.defaultValue = defaultValue
    }
    
    
    public convenience init(wrappedValue: Value, _ validator: Validator<Value>) {
        self.init(wrappedValue: wrappedValue, using: validator)
    }
    
}



extension Validate where Value: Validatable {

    public convenience init(wrappedValue: Value) {
        self.init(wrappedValue: wrappedValue, using: Validator<Value>.valid)
    }
}

@propertyWrapper
public final class ValidateOr<Value> {
    
    private var value: Value? = nil
    
    private var validator: Validator<Value>
    
    private var defaultValue: Value
    
    public var error: String? = nil
    
    public var wrappedValue: Value {
        get {
            guard let value = self.value, self.isValid else {
                return defaultValue
            }
            return value
        }
        set {
            value = newValue
            validate()
        }
    }
    
    public func validate() {
        guard let value = self.value else {
            return
        }
        do {
            try validator.validate(value)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    public var isValid: Bool {
        validate()
        return error == nil
    }
    
    public var projectedValue: ValidateOr<Value> {
        return self
    }
    
   
    
    public init(wrappedValue: Value, using validator: Validator<Value>, with defaultValue: Value) {
           self.validator = validator
           self.defaultValue = defaultValue
           self.wrappedValue = wrappedValue
    }
    
    
    public convenience init(wrappedValue: Value, _ validator: Validator<Value>, with defaultValue: Value) {
        self.init(wrappedValue: wrappedValue, using: validator, with: defaultValue)
    }
    
}



extension ValidateOr where Value: Validatable {

    public convenience init(wrappedValue: Value, with defaultValue: Value) {
        self.init(wrappedValue: wrappedValue, using: Validator<Value>.valid, with: defaultValue)
    }
}

