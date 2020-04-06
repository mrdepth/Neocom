//
//  FetchedResultsController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/26/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import Combine

class FetchedResultsController<ResultType: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private let controller: NSFetchedResultsController<ResultType>
    
    struct Section {
        var name: String
        var objects: [ResultType]
    }
    
    private var isFetched: Bool = false
    private var _sections: [Section]?
    var sections: [Section] {
        if !isFetched {
            try! controller.performFetch()
            isFetched = true
        }
        if _sections == nil {
            _sections = controller.sections?.map { return Section(name: $0.name, objects: ($0.objects as? [ResultType]) ?? []) } ?? []
        }
        return _sections ?? []
    }
    
    var fetchedObjects: [ResultType] {
        if !isFetched {
            try! controller.performFetch()
            isFetched = true
        }
        return controller.fetchedObjects ?? []
    }
    
    
    let objectWillChange = ObservableObjectPublisher()
    
    lazy var publisher: AnyPublisher<[Section], Never> = {
        if subject == nil {
            subject = CurrentValueSubject(sections)
        }
        return subject!.eraseToAnyPublisher()
    }()
    
    private var subject: CurrentValueSubject<[Section], Never>?
    
    init(_ controller: NSFetchedResultsController<ResultType>) {
        self.controller = controller
        super.init()
        if controller.fetchRequest.resultType == .managedObjectResultType {
            controller.delegate = self
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        objectWillChange.send()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        _sections = controller.sections?.map { return Section(name: $0.name, objects: ($0.objects as? [ResultType]) ?? []) } ?? []
        subject?.send(sections)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    }
    
}

