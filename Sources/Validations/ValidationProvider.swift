//
//  File.swift
//  
//
//  Created by Michael Housh on 8/24/19.
//

import Combine

@available(iOS 13, macOS 10.15, *)
extension Publisher {
    
    @available(iOS 13, macOS 10.15, *)
    public func validate<T>(_ validator: Validator<T>) -> ValidationPublisher<Self> where Output == T {
        return ValidationPublisher(upstream: self, validator: validator)
    }
}


@available(iOS 13, macOS 10.15, *)
public struct ValidationPublisher<Upstream: Publisher>: Publisher where Upstream.Failure == Never {
    
    public typealias Output = Upstream.Output?
    public typealias Failure = Never
    
    public let upstream: Upstream
    public let validator: Validator<Upstream.Output>
    
    
    public init(upstream: Upstream, validator: Validator<Upstream.Output>) {
        self.upstream = upstream
        self.validator = validator
    }
    
    public func receive<Downstream>(subscriber: Downstream) where Downstream : Subscriber, Failure == Downstream.Failure, Output == Downstream.Input {
        let inner = Inner<Upstream, Downstream>(validator: validator, downstream: subscriber)
        upstream.subscribe(inner)
    }
}

@available(iOS 13, macOS 10.15, *)
private final class Inner<Upstream: Publisher, Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomReflectable where Downstream.Input == Upstream.Output? {
    
    typealias Input = Upstream.Output
    typealias Failure = Never
    typealias Output = Upstream.Output?
    
    var description: String { return "Validation" }
    
    private var _downstream: Downstream? = nil
    private let _validator: Validator<Upstream.Output>
    private var _upstreamSubscription: Subscription? = nil
    
    init(validator: Validator<Upstream.Output>, downstream: Downstream) {
        self._validator = validator
        self._downstream = downstream
    }
    
    func cancel() {
        _downstream = nil
    }
    
    func request(_ demand: Subscribers.Demand) {

    }
    
    func receive(_ input: Upstream.Output) -> Subscribers.Demand {
        let value: Upstream.Output?
        
        do {
            try _validator.validate(input)
            value = input
        } catch {
            value = nil
        }
        return _downstream?.receive(value) ?? .none
    }
    
    func receive(subscription: Subscription) {
        _upstreamSubscription = subscription
        _downstream?.receive(subscription: self)
        _upstreamSubscription?.request(.unlimited)
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        //_downstream?.receive(completion: completion)
    }
    
    var customMirror: Mirror {
        return Mirror(self, unlabeledChildren: CollectionOfOne(_validator))
    }
}
