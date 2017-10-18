//
//  NCFetchedCollection.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

class NCFetchedCollection<Element : NSFetchRequestResult> {
	let entityName: String
	let predicateFormat: String
	let argumentArray:[Any]
	let managedObjectContext: NSManagedObjectContext
	let request: NSFetchRequest<Element>
	
	init(entityName: String, predicateFormat: String, argumentArray:[Any], managedObjectContext: NSManagedObjectContext) {
		self.entityName = entityName
		self.predicateFormat = predicateFormat
		self.argumentArray = argumentArray
		self.managedObjectContext = managedObjectContext
		self.request = NSFetchRequest<Element>(entityName: entityName)
	}
	
	subscript(index: Int) -> Element? {
		var argumentArray = self.argumentArray
		argumentArray.append(index)
		request.predicate = NSPredicate(format: self.predicateFormat, argumentArray: argumentArray)
		return (try? managedObjectContext.fetch(request))?.last
	}
	
	subscript(key: String) -> Element? {
		var argumentArray = self.argumentArray
		argumentArray.append(key)
		request.predicate = NSPredicate(format: self.predicateFormat, argumentArray: argumentArray)
		return (try? managedObjectContext.fetch(request))?.last
	}

}
