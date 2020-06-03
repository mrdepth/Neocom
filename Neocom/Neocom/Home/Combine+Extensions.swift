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

extension Progress {
    func performAsCurrent<ReturnType>(withPendingUnitCount unitCount: Int64, totalUnitCount: Int64, using work: (Progress) throws -> ReturnType) rethrows -> ReturnType {
        try performAsCurrent(withPendingUnitCount: unitCount) {
            try work(Progress(totalUnitCount: totalUnitCount))
        }
    }
}

struct FileChangesPublisher: Publisher {
    typealias Output = Void
    typealias Failure = RuntimeError
    
    var path: String
    var eventMask: DispatchSource.FileSystemEvent = .all

    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        subscriber.receive(subscription: FileChangesPublisherSubscription(subscriber: subscriber, path: path, eventMask: eventMask))
    }

    private class FileChangesPublisherSubscription<S: Subscriber>: Subscription where S.Failure == Failure, S.Input == Output {
        var source: DispatchSourceFileSystemObject?
        
        func cancel() {
            source?.cancel()
            source = nil
        }
        
        private var demand = Subscribers.Demand.none
        private var parentFolderSubscription: AnyCancellable?
        
        private func makeSource() -> DispatchSourceFileSystemObject? {
            let fd = open(path, O_EVTONLY)
            guard fd >= 0 else {return nil}
            let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: eventMask, queue: .main)
            source.setCancelHandler {
                close(fd)
            }
            source.setEventHandler { [weak self] in
                guard let strongSelf = self else {return}
                if strongSelf.demand > 0 {
                    strongSelf.demand -= 1
                    strongSelf.demand += strongSelf.subscriber.receive()
                }
            }
            source.resume()
            return source
        }
        
        func request(_ demand: Subscribers.Demand) {
            self.demand = demand
            if source == nil {
                
                if let source = makeSource() {
                    self.source = source
                }
                else {
                    let path = URL(fileURLWithPath: self.path).deletingLastPathComponent().path
                    guard path != "/" else {
                        subscriber.receive(completion: .failure(RuntimeError.fileNotFound(path)))
                        return
                    }
                    
                    parentFolderSubscription = FileChangesPublisher(path: path).sink(receiveCompletion: { [weak self] (completion) in
                        if case .failure = completion {
                            self?.subscriber.receive(completion: completion)
                        }
                    }) { [weak self] () in
                        if let source = self?.makeSource() {
                            self?.source = source
                            _ = self?.subscriber.receive(())
                            self?.parentFolderSubscription = nil
                        }
                    }
                }
            }
        }

        var subscriber: S
        var path: String
        var eventMask: DispatchSource.FileSystemEvent
        
        init(subscriber: S, path: String, eventMask: DispatchSource.FileSystemEvent) {
            self.subscriber = subscriber
            self.path = path
            self.eventMask = eventMask
        }
    }
    
}
