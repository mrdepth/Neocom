//
//  FetchedResultsController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/26/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

class FetchedResultsController<ResultType: NSFetchRequestResult>: ObservableObject {
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
            _sections = controller.sections?.map { return Section(name: $0.name, objects: ($0.objects as? [ResultType]) ?? []) }
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
    
    init(_ controller: NSFetchedResultsController<ResultType>) {
        self.controller = controller
    }
}
