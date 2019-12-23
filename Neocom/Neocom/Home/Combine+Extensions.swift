//
//  Combine+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/22/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import CoreData

extension Publisher where Failure: Error {
    func asResult() -> Publishers.Catch<Publishers.Map<Self, Result<Self.Output, Self.Failure>>, Just<Result<Self.Output, Self.Failure>>> {
		return map{Result.success($0)}.catch{Just(Result.failure($0))}
    }
}

extension Publisher {
	func tryGet<S, F: Error>() -> Publishers.MapError<Publishers.TryMap<Self, S>, F> where Output == Result<S, F>, Failure == Never {
		tryMap {try $0.get()}.mapError{$0 as! F}
	}
}

extension Result {

    var value: Success? {
        switch self {
        case let .success(value):
            return value
        default:
            return nil
        }
    }

    var error: Failure? {
        switch self {
        case let .failure(error):
            return error
        default:
            return nil
        }
    }
}


extension NSManagedObjectContext: Scheduler {
    
    public func schedule(after date: DispatchQueue.SchedulerTimeType, interval: DispatchQueue.SchedulerTimeType.Stride, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
        DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: nil) {
            self.perform(action)
        }
    }
    
    public func schedule(after date: DispatchQueue.SchedulerTimeType, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
        DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: nil) {
            self.perform(action)
        }
    }
    
    public func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        self.perform(action)
    }
    
    public var now: DispatchQueue.SchedulerTimeType {
        DispatchQueue.main.now
    }
    
    public var minimumTolerance: DispatchQueue.SchedulerTimeType.Stride {
        DispatchQueue.main.minimumTolerance
    }
    
    public typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
    
    public typealias SchedulerOptions = Never
    
    
}
