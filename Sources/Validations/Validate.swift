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
 
    @Validate(!.empty && .count(1..<5))
    var lessThanFive: String? = nil
 
 }
 
 let myObject = MyObject()
 myObject.lessThanFive = "abcdefg"
 myObject.$lessThanFive.isValid
 // false
 
 myObject.lessThanFive == ""
 print(myObject.$lessThanFive.error!)
 // ⚠️ [AndValidatorError.validationFailed: data is empty and data is less than required minimum of 1 character]
 
 myObject.lessThanFive = "123"
 myObject.$lessThanFive.isValid
 // true
 
 myObject.lessThanFive = "more than five"
 myObject.$lessThanFive.isValid
 // false
 
 myObject.lessThanFive == nil
 // true
 ```
 
 
 */
@propertyWrapper
public struct Validate<Value> {
    
    /// Holds a `Result` of the latest validation.
    private var result: Result<Value, BasicValidationError>
    
    /// The validator used to validate the `wrappedValue`.
    public var validator: Validator<Value>
    
    /// The current value whether it's valid or not.
    public private(set) var value: Value? = nil
    
    /// The current error, from latest validation.
    public var error: BasicValidationError? {
        switch result {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
    
    /// The default value to return if validation fails.
    public var defaultValue: Value
    
    /// The value returned when accessing the wrapped property.
    /// If the current value is valid, then it is returned, else the `defaultValue` is returned.
    public var wrappedValue: Value {
        get {
            switch result {
            case .success(let value):
                return value
            default:
                return defaultValue
            }
        }
        mutating set {
            value = newValue
            validate(newValue)
        }
    }
    
    /// Convenience to check if current value is valid.
    public var isValid: Bool {
        return error == nil
    }
    
    /// Allows access with the `$` prefix.
    public var projectedValue: Validate<Value> {
        return self
    }
    
    /// Validates the value and set's our current `result`.
    mutating func validate(_ value: Value) {
        self.result = validator.result(for: value)
    }
    
    /// Initialiizes a new property with the given values.
    ///
    /// - parameter wrappedValue: This passed via the wrapped property.
    /// - parameter default: The default value returned if validations fail
    /// - parameter validator: The vallidator to use to validate values for the property
    ///
    /// ```
    /// struct MyObject {
    ///
    ///     @Validate(default: "foo-bar", !.empty && .count(3...))
    ///     var string: String = ""
    ///
    /// }
    ///
    /// var x = MyObject()
    /// print(x.string)
    /// // foo-bar
    ///
    /// x.string = "bar-foo"
    /// print(x.string)
    /// // bar-foo
    ///
    /// x.string = "fo"
    /// x.$string.isValid
    /// // false
    ///
    /// ```
    ///
    public init(wrappedValue: Value, default defaultValue: Value, _ validator: Validator<Value>) {
        self.validator = validator
        self.defaultValue = defaultValue
        self.result = validator.result(for: wrappedValue)
        self.wrappedValue = wrappedValue
    }
    
}


extension Validate where Value: ExpressibleByNilLiteral {
    
    /// Initialiizes a new property with the given values and set's the `defaultValue` to `nil`
    ///
    /// - parameter wrappedValue: This passed via the wrapped property.
    /// - parameter validator: The vallidator to use to validate values for the property
    ///
    /// ```
    /// struct MyObject {
    ///
    ///     @Validate(!.empty && .count(3...))
    ///     var string: String? = nil
    ///
    /// }
    ///
    /// var x = MyObject()
    /// print(x.string ?? "empty")
    /// // empty
    ///
    /// x.string = "bar-foo"
    /// print(x.string ?? "empty")
    /// // bar-foo
    ///
    /// x.string = "fo"
    /// x.$string.isValid
    /// // false
    ///
    /// ```
    ///
    public init(wrappedValue: Value, _ validator: Validator<Value>) {
        self.defaultValue = nil
        self.validator = validator
        self.result = validator.result(for: wrappedValue)
        self.wrappedValue = wrappedValue
    }
}

extension Result where Failure == BasicValidationError {
    
    /// Initializes a new `Result<Success, BasicValidationError>`.
    ///
    /// - parameter value: The value to validate.
    /// - parameter validator: The validator to use to validate the value.
    ///
    /// - Returns: A `Result.success` if the value is valid or a `Result.failure` if it does not.
    ///
    public init(_ value: Success, validator: Validator<Success>) {
        do {
            try validator.validate(value)
            self = .success(value)
        } catch {
            self = .failure(BasicValidationError(error.localizedDescription))
        }
    }
    
}

extension Validator {
    
    /// Validates a value and returns a `Result<T, BasicValidationError>` .
    public func result(for value: T) -> Result<T, BasicValidationError> {
        return Result(value, validator: self)
    }
}
