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

class Cache_Tests: XCTestCase {
	
    override func setUp() {
        super.setUp()
		try? cache.viewContext.managedObjectContext.from(CacheRecord.self).all().forEach {
			$0.managedObjectContext?.delete($0)
		}
		
		try? cache.viewContext.save()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConflicts() {
		
		var aObjectID: NSManagedObjectID?
		
		let a = cache.performBackgroundTask { (context) -> Void in
			let entry = context.newRecord(identifier: "test", account: "account")
			entry.date = Date()
			entry.cachedUntil = Date(timeIntervalSinceNow: 3600)
			entry.setValue("a")
			entry.etag = "a"
			Thread.sleep(forTimeInterval: 0.5)
			try! context.save()
			aObjectID = entry.objectID
		}
		let b = cache.performBackgroundTask { (context) -> Void in
			let entry = context.newRecord(identifier: "test", account: "account")
			entry.date = Date()
			entry.cachedUntil = Date(timeIntervalSinceNow: 3600)
			entry.setValue("b")
			entry.etag = "b"
			a.wait()
			do {
				try context.save()
				XCTFail()
			}
			catch {
				let conflicts = (error as NSError).userInfo[NSPersistentStoreSaveConflictsErrorKey] as! [NSConstraintConflict]
				XCTAssertEqual(conflicts.count, 1)
				let databaseObject = conflicts[0].databaseObject! as! CacheRecord
				databaseObject.etag = "b"
				databaseObject.setValue("b")
				context.managedObjectContext.delete(entry)
				try! context.save()
				XCTAssertEqual(databaseObject.objectID, aObjectID)
			}
		}
		let exp = expectation(description: "wait")
//		a.finally(on: .main) {
//			let record = try! cache.viewContext.managedObjectContext.from(CacheRecord.self).first()
//			XCTAssertEqual(record?.data?.value, try! JSONEncoder().encode(["a"]))
//		}
		
		b.finally {
			cache.performBackgroundTask { context -> Void in
				let records = try! context.managedObjectContext.from(CacheRecord.self).all()
				XCTAssertEqual(records.count, 1)
				XCTAssertEqual(records.first?.getValue(), "b")
				XCTAssertEqual(records.first?.etag, "b")
				XCTAssertEqual(records.first?.objectID, aObjectID)

				exp.fulfill()
			}
		}
		wait(for: [exp], timeout: 10)
    }
    
}
