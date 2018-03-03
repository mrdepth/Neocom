//
//  NSManagedObjectContext+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
	public func fetch<Type:NSFetchRequestResult>(_ entityName:String, limit: Int = 0, sortedBy:[NSSortDescriptor] = [], `where`: String? = nil, _ args: CVarArg...) -> Type? {
		let request = NSFetchRequest<Type>(entityName: entityName)
		request.sortDescriptors = sortedBy
		request.fetchLimit = limit
		if let pred = `where` {
			request.predicate = withVaList(args) {
				return NSPredicate(format: pred, arguments: $0)
			}
		}
		request.fetchLimit = 1
		return (try? self.fetch(request))?.first
	}
	
	public func fetch<Type:NSFetchRequestResult>(_ entityName:String, limit: Int = 0, sortedBy:[NSSortDescriptor] = [], `where`: String? = nil, _ args: CVarArg...) -> [Type]? {
		let request = NSFetchRequest<Type>(entityName: entityName)
		request.sortDescriptors = sortedBy
		request.fetchLimit = limit
		if let pred = `where` {
			request.predicate = withVaList(args) {
				return NSPredicate(format: pred, arguments: $0)
			}
		}
		return (try? self.fetch(request))
	}

}
