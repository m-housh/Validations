//
//  File.swift
//  
//
//  Created by Michael Housh on 8/24/19.
//

import Validations
import Combine
import XCTest

@available(macOS 10.15, iOS 13, *)
class PublisherTests: XCTestCase {
    
    func testPublisher() {
        let p = CapturingPublisher<String>(!.empty && .count(3...))
        p.value = ""
        XCTAssertNil(p.value)
        p.value = "foo-bar"
        XCTAssertEqual(p.value, "foo-bar")
        p.value = "foo"
        XCTAssertEqual(p.value, "foo")
        p.value = "fo"
        XCTAssertNil(p.value)
    }
    
    func testTryValidate() {
        let p = CapturingPublisher<String>(!.empty && .count(3...), .tryValidate, tryFailure: "failed")
        //XCTAssertEqual(p.value, "failed")
        p.value = "foo-bar"
        XCTAssertEqual(p.value, "foo-bar")

    }

}

@available(macOS 10.15, iOS 13, *)
final class CapturingPublisher<T> {
    
    var subject = PassthroughSubject<T, Never>()
    var trySubject = PassthroughSubject<T, BasicValidationError>()
    var subscription: AnyCancellable? = nil
    let validator: Validator<T>
    let type: PublisherType
    var tryFailure: T? = nil
    
    var _value: T? = nil
    
    var value: T? {
        get { _value }
        set {
            guard let value = newValue else {
                return
            }
            
            switch type {
            case .tryValidate:
                trySubject.send(value)
            default:
                subject.send(value)
            }
            //subject.send(value)
        }
    }
    
    init(_ validator: Validator<T>, _ type: PublisherType = .validate, tryFailure: T? = nil) {
        self.validator = validator
        self.type = type
        self.tryFailure = tryFailure
        setup()
    }
    
    func setup() {
        switch type {
        case .tryValidate:
            subscription = trySubject
                .tryValidate(self.validator)
                .replaceError(with: tryFailure!)
                .sink { self._value = $0 }
            
        default:
            subscription = subject
                .validate(self.validator)
                .sink { self._value = $0 }
        }
    }
    
    deinit {
        subscription?.cancel()
        subscription = nil
    }

    enum PublisherType {
        case tryValidate
        case validate
    }
}
