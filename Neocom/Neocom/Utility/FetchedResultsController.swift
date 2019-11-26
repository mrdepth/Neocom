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
        var name: String {
            return section.name
        }
        var objects: [ResultType] {
            return section.objects as? [ResultType] ?? []
        }

        fileprivate var section: NSFetchedResultsSectionInfo
    }
    
    private var isFetched: Bool = false
    var sections: [Section] {
        if !isFetched {
            try! controller.performFetch()
            isFetched = true
        }
        return (controller.sections ?? []).map { return Section(section: $0) }
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
