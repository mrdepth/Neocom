//
//  NCCacheRecord+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

extension NCCacheRecord {
	@nonobjc class func fetchRequest(forKey key: String?, account: String?) -> NSFetchRequest<NCCacheRecord> {
		let request = NSFetchRequest<NCCacheRecord>(entityName: "Record");
		var predicates = [NSPredicate]()
		if let key = key {
			predicates.append(NSPredicate(format: "key == %@", key))
			request.fetchLimit = 1
		}
		if let account = account {
			predicates.append(NSPredicate(format: "account == %@", account))
		}
		
		request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
		return request
	}
	
	var expired: Bool {
		get {
			guard self.date != nil else {return true}
			guard let expireDate = self.expireDate as? Date else {return true}
			return Date() > expireDate
		}
	}
}
