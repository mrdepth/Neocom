//
//  Cache_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 22.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import Neocom
import CoreData
import Futures
import Expressible

class Cache_Tests: TestCase {
	
    override func setUp() {
        super.setUp()
    }
	
	func testContacts() {
		let context = Services.cache.viewContext.managedObjectContext
		let a = Contact(context: context)
		a.contactID = 1
		a.name = "a"
		try! context.save()
		
		let exp = expectation(description: "end")
		
		Services.cache.performBackgroundTask { context in
			let b = Contact(context: context.managedObjectContext)
			b.contactID = 1
			b.name = "b"
			
			let c = Contact(context: context.managedObjectContext)
			c.contactID = 3
			c.name = "c"
			
			do {
				try context.save()
			}
			catch {
				if let error = error as? CocoaError, error.errorCode == CocoaError.managedObjectConstraintMerge.rawValue, let conflicts = error.errorUserInfo[NSPersistentStoreSaveConflictsErrorKey] as? [NSConstraintConflict] {
					conflicts.flatMap {$0.conflictingObjects}.forEach {
						context.managedObjectContext.delete($0)
					}
					try! context.save()
				}
				else {
					XCTFail()
				}
			}
			
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 10)
		
		try! XCTAssertEqual(context.from(Contact.self).count(), 2)


	}
    
    override func tearDown() {
        super.tearDown()
    }
}
