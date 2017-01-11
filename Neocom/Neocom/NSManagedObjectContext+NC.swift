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
	func fetch<Type:NSFetchRequestResult>(_ entityName:String, `where`: String, _ args: CVarArg...) -> Type? {
		let request = NSFetchRequest<Type>(entityName: entityName)
		request.predicate = withVaList(args) {
			return NSPredicate(format: `where`, arguments: $0)
		}
		request.fetchLimit = 1
		return (try? self.fetch(request))?.first
	}
}
