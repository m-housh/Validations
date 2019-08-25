# Validations

A package for validating objects, such as `name`, `email`, etc.  This is a stripped down fork of [vapor/validation](https://github.com/vapor/validation).


## Usage

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

