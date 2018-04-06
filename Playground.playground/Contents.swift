//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

public enum FutureError: Error {
	case promiseAlreadySatisfied
	case timeout
}

public enum FutureState<Value> {
	case pending
	case success(Value)
	case failure(Error)
}

final public class Future<Value>: NSLocking {
	
	fileprivate(set) public var state: FutureState<Value> = .pending {
		didSet {
			condition.broadcast()
		}
	}
	
	fileprivate var condition = NSCondition()
	fileprivate var success = [(DispatchQueue?, (Value) -> Void)]()
	fileprivate var failure = [(DispatchQueue?, (Error) -> Void)]()
	fileprivate var finally = [(DispatchQueue?, () -> Void)]()
	
	public init(_ state: FutureState<Value> = .pending) {
	}
	
	public convenience init(_ value: Value) {
		self.init(.success(value))
	}
	
	public func lock() {
		condition.lock()
	}
	
	public func unlock() {
		condition.unlock()
	}
	
	public func get(until: Date = .distantFuture) throws -> Value {
		return try condition.perform {
			while case .pending = state, Date() < until {
				condition.wait(until: until)
			}
			switch state {
			case let .success(value):
				return value
			case let .failure(error):
				throw error
			case .pending:
				throw FutureError.timeout
			}
		}
	}
	
	public func wait(until: Date = .distantFuture) {
		condition.perform {
			while case .pending = state, Date() < until {
				condition.wait(until: until)
			}
		}
	}
	
	@discardableResult
	public func then<Result>(on queue: DispatchQueue? = nil, _ execute: @escaping (Value, Promise<Result>) throws -> Void) -> Future<Result> {
		
		let promise = Promise<Result>()
		
		let onSuccess = { (value: Value) in
			do {
				try execute(value, promise)
			}
			catch {
				try! promise.fail(error)
			}
		}
		
		condition.perform { () -> (() -> Void)? in
			switch state {
			case let .success(value):
				return {
					if let queue = queue {
						queue.async {
							onSuccess(value)
						}
					}
					else {
						onSuccess(value)
					}
				}
			case let .failure(error):
				return {
					try! promise.fail(error)
				}
			case .pending:
				success.append((queue, onSuccess))
				failure.append((queue, { error in try! promise.fail(error) }))
				return nil
			}
			}?()
		
		return promise.future
	}
	
	@discardableResult
	public func `catch`(on queue: DispatchQueue? = nil, _ execute: @escaping (Error) -> Void) -> Self {
		condition.perform { () -> (() -> Void)? in
			switch state {
			case let .failure(error):
				return { execute(error) }
			case .success:
				return nil
			case .pending:
				failure.append((queue, execute))
				return nil
			}
			}?()
		return self
	}
	
	@discardableResult
	public func finally(on queue: DispatchQueue? = nil, _ execute: @escaping () -> Void) -> Self {
		
		condition.perform { () -> (() -> Void)? in
			switch state {
			case .success, .failure:
				return { execute() }
			case .pending:
				finally.append((queue, execute))
				return nil
			}
			}?()
		return self
	}
	
	@discardableResult
	public func then<Result>(on queue: DispatchQueue? = nil, _ execute: @escaping (Value) throws -> Future<Result>) -> Future<Result> {
		return then(on: queue) { (value: Value, promise: Promise<Result>) in
			try execute(value).then { value in
				try! promise.fulfill(value)
			}.catch { error in
				try! promise.fail(error)
			}
		}
	}

}

extension Future {
	@discardableResult
	public func then<Result>(on queue: DispatchQueue? = nil, _ execute: @escaping (Value) throws -> Result) -> Future<Result> {
		return then(on: queue) { (value: Value, promise: Promise<Result>) in
			try promise.fulfill(execute(value))
		}
	}
}

open class Promise<Value> {
	open var future = Future<Value>()
	
	public init() {}
	
	open func fulfill(_ value: Value) throws {
		try future.perform { () -> () -> Void in
			guard case .pending = future.state else { throw FutureError.promiseAlreadySatisfied }
			defer {
				future.success = []
				future.failure = []
				future.finally = []
			}
			
			future.state = .success(value)
			
			let execute = self.future.success
			let finally = self.future.finally
			
			return {
				execute.forEach { (queue, block) in
					if let queue = queue {
						queue.async {
							block(value)
						}
					}
					else {
						block(value)
					}
				}
				finally.forEach { (queue, block) in
					if let queue = queue {
						queue.async {
							block()
						}
					}
					else {
						block()
					}
				}
			}
			}()
	}
	
	open func fail(_ error: Error) throws {
		try future.perform { () -> () -> Void in
			guard case .pending = future.state else { throw FutureError.promiseAlreadySatisfied }
			defer {
				future.success = []
				future.failure = []
				future.finally = []
			}
			
			future.state = .failure(error)
			
			let execute = self.future.failure
			let finally = self.future.finally
			return {
				execute.forEach { (queue, block) in
					if let queue = queue {
						queue.async {
							block(error)
						}
					}
					else {
						block(error)
					}
				}
				finally.forEach { (queue, block) in
					if let queue = queue {
						queue.async {
							block()
						}
					}
					else {
						block()
					}
				}
			}
			}()
	}
}


extension OperationQueue {
	
	public convenience init (qos: QualityOfService, maxConcurrentOperationCount: Int = OperationQueue.defaultMaxConcurrentOperationCount) {
		self.init()
		self.qualityOfService = qos
		self.maxConcurrentOperationCount = maxConcurrentOperationCount
	}
	
	@discardableResult
	public func async<Value>(_ execute: @escaping () throws -> Value) -> Future<Value> {
		let promise = Promise<Value>()
		addOperation {
			do {
				try promise.fulfill(execute())
			}
			catch {
				try! promise.fail(error)
			}
		}
		return promise.future
	}
}

extension DispatchQueue {
	public func async<Value>(_ execute: @escaping () throws -> Value) -> Future<Value> {
		let promise = Promise<Value>()
		async {
			do {
				try promise.fulfill(execute())
			}
			catch {
				try! promise.fail(error)
			}
		}
		return promise.future
	}
}

extension NSLocking {
	@discardableResult
	public func perform<Value>(_ execute: () throws -> Value) rethrows -> Value {
		lock(); defer { unlock() }
		return try execute()
	}
}


open class TreeNode {
	
}


func first() -> Future<TreeNode> {
	return DispatchQueue.main.async {
		return TreeNode()
	}
}

func second() -> Future<TreeNode> {
	return first().then(on: .main) { content in
//		let i = 10
//		var m = max(i, 15)
		return content
	}.catch(on: .main) { error in
	}
}


second()

