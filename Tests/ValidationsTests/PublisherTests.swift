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
        let p = CapturingPublisher()
        p.value = ""
        XCTAssertNil(p.value)
        p.value = "foo-bar"
        XCTAssertEqual(p.value, "foo-bar")
        p.value = "foo"
        XCTAssertEqual(p.value, "foo")
        p.value = "fo"
        XCTAssertNil(p.value)

    }
    
}

@available(macOS 10.15, iOS 13, *)
final class CapturingPublisher: Codable, Reflectable {
    
    let subject = PassthroughSubject<String, Never>()
    var subscription: AnyCancellable? = nil
    
    var _value: String? = nil
    
    var value: String? {
        get { _value }
        set {
            guard let value = newValue else {
                return
            }
            subject.send(value)
        }
    }
    
    init() {
        setup()
    }
    
    func setup() {
        subscription = subject
            .validate(!.empty && .count(3...))
            .sink { self._value = $0 }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    required init(from decoder: Decoder) throws {
        setup()
        let container = try decoder.singleValueContainer()
        if let string = try container.decode(String?.self) {
            self.value = string
        }
    }
}
