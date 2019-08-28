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
    
    @available(iOS 13, macOS 10.15, *)
   public func tryValidate<T>(_ validator: Validator<T>) -> TryValidationPublisher<Self> where Output == T {
       return TryValidationPublisher(upstream: self, validator: validator)
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
public struct TryValidationPublisher<Upstream: Publisher>: Publisher where Upstream.Failure == BasicValidationError {
    
    public typealias Output = Upstream.Output
    public typealias Failure = BasicValidationError
    
    public let upstream: Upstream
    public let validator: Validator<Upstream.Output>
    
    
    public init(upstream: Upstream, validator: Validator<Upstream.Output>) {
        self.upstream = upstream
        self.validator = validator
    }
    
    public func receive<Downstream>(subscriber: Downstream) where Downstream : Subscriber, Failure == Downstream.Failure, Output == Downstream.Input {
        let inner = TryInner<Upstream, Downstream>(validator: validator, downstream: subscriber)
        upstream.subscribe(inner)
    }
}



@available(iOS 13, macOS 10.15, *)
internal class OperatorSubscription<Downstream: Subscriber>: CustomReflectable {
    
    internal var downstream: Downstream?
    internal var upstreamSubscription: Subscription?
    
    internal init(downstream: Downstream) {
        self.downstream = downstream
    }
    
    internal var customMirror: Mirror {
        return Mirror(self, children: EmptyCollection())
    }
    
    internal func cancel() {
        upstreamSubscription?.cancel()
        upstreamSubscription = nil
        downstream = nil
    }
    
    internal func request(_ demand: Subscribers.Demand) {
        
    }
}

@available(iOS 13, macOS 10.15, *)
private final class Inner<Upstream: Publisher, Downstream: Subscriber>: OperatorSubscription<Downstream>, Subscriber, Subscription, CustomStringConvertible where Downstream.Input == Upstream.Output? {
    
    typealias Input = Upstream.Output
    typealias Failure = Never
    typealias Output = Upstream.Output?
    
    var description: String { return "Validation" }
    
    private let _validator: Validator<Upstream.Output>
    
    init(validator: Validator<Upstream.Output>, downstream: Downstream) {
        self._validator = validator
        super.init(downstream: downstream)
    }
    
    func receive(_ input: Upstream.Output) -> Subscribers.Demand {
        let value: Upstream.Output?
        
        do {
            try _validator.validate(input)
            value = input
        } catch {
            value = nil
        }
        return downstream?.receive(value) ?? .none
    }
    
    func receive(subscription: Subscription) {
       upstreamSubscription = subscription
       downstream?.receive(subscription: self)
       upstreamSubscription?.request(.unlimited)
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        //_downstream?.receive(completion: completion)
    }
    
    override var customMirror: Mirror {
        return Mirror(self, unlabeledChildren: CollectionOfOne(_validator))
    }
}


@available(iOS 13, macOS 10.15, *)
private final class TryInner<Upstream: Publisher, Downstream: Subscriber>: OperatorSubscription<Downstream>, Subscriber, Subscription, CustomStringConvertible where Downstream.Input == Upstream.Output, Downstream.Failure == BasicValidationError {
    
    
    typealias Input = Upstream.Output
    typealias Failure = BasicValidationError
    typealias Output = Upstream.Output
    
    var description: String { return "Try Validation" }
    
    private let _validator: Validator<Upstream.Output>
    
    init(validator: Validator<Upstream.Output>, downstream: Downstream) {
        self._validator = validator
        super.init(downstream: downstream)
    }
    
    func receive(_ input: Upstream.Output) -> Subscribers.Demand {
       // let value: Upstream.Output
        guard let downstream = downstream else { return .none }
        
        do {
            try _validator.validate(input)
            return downstream.receive(input)
        } catch {
            print("error: \(error)")
            downstream.receive(completion: .failure(BasicValidationError(error.localizedDescription)))
            //return .none
        }
        return .none
    }
    
    func receive(subscription: Subscription) {
       upstreamSubscription = subscription
       downstream?.receive(subscription: self)
       upstreamSubscription?.request(.unlimited)
    }
    
    func receive(completion: Subscribers.Completion<BasicValidationError>) {
        downstream?.receive(completion: completion)
        //cancel()
    }
    
    override var customMirror: Mirror {
        return Mirror(self, unlabeledChildren: CollectionOfOne(_validator))
    }
}
