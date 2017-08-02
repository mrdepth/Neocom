//
//  NCCache.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import EVEAPI


class NCCache: NSObject {
	private(set) lazy var managedObjectModel: NSManagedObjectModel = {
		NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "NCCache", withExtension: "momd")!)!
	}()
	
	private(set) lazy var viewContext: NSManagedObjectContext = {
		var viewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator
		NotificationCenter.default.addObserver(self, selector: #selector(NCCache.managedObjectContextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
		return viewContext
	}()
	
	private(set) lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		var persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let directory = URL.init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]).appendingPathComponent("com.shimanski.eveuniverse.NCCache")
		try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
		let url = directory.appendingPathComponent("store.sqlite")
		
		for i in 0...1 {
			do {
				try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
				                                                   configurationName: nil,
				                                                   at: url,
				                                                   options: nil)
				break
			} catch {
				try? FileManager.default.removeItem(at: url)
			}
		}
		
		return persistentStoreCoordinator
	}()
	
	static let sharedCache: NCCache? = NCCache()
	
	override init() {
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		context.persistentStoreCoordinator = persistentStoreCoordinator
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.perform {
			block(context)
			if context.hasChanges {
				try? context.save()
			}
		}
	}
	
	func performTaskAndWait(_ block: @escaping (NSManagedObjectContext) -> Void) {
		let context = NSManagedObjectContext(concurrencyType: Thread.isMainThread ? .mainQueueConcurrencyType : .privateQueueConcurrencyType)
		context.persistentStoreCoordinator = persistentStoreCoordinator
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.performAndWait {
			block(context)
			if context.hasChanges {
				try? context.save()
			}
		}
	}
	
	func store(_ object: NSSecureCoding?, forKey key: String, account: String?, date: Date?, expireDate: Date?, error: Error?, completionHandler: ((NCCacheRecord?) -> Void)?) {
		performBackgroundTask { (managedObjectContext) in
			var record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)))?.last
			if record == nil {
				
				let r = NCCacheRecord(entity: NSEntityDescription.entity(forEntityName: "Record", in: managedObjectContext)!, insertInto: managedObjectContext)
				r.account = account
				r.key = key
				r.data = NCCacheRecordData(entity: NSEntityDescription.entity(forEntityName: "RecordData", in: managedObjectContext)!, insertInto: managedObjectContext)
				record = r
			}
			if object != nil || record!.data!.data == nil {
				record!.data?.data = object
				record!.date = (date ?? Date()) as NSDate?
				record!.expireDate = (expireDate as NSDate?) ?? record!.expireDate ?? record!.date!.addingTimeInterval(3) as NSDate?
			}
			if managedObjectContext.hasChanges {
				try? managedObjectContext.save()
			}
			if let completionHandler = completionHandler {
				DispatchQueue.main.async {
					completionHandler((try? self.viewContext.existingObject(with: record!.objectID)) as? NCCacheRecord)
				}
			}
		}
	}
	
	//MARK: Private
	
	func managedObjectContextDidSave(_ notification: Notification) {
		guard let context = notification.object as? NSManagedObjectContext,
			viewContext !== context && context.persistentStoreCoordinator === viewContext.persistentStoreCoordinator
			else {
				return
		}
		viewContext.perform {
			self.viewContext.mergeChanges(fromContextDidSave: notification)
		}
	}
}


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
	
	var isExpired: Bool {
		get {
			guard self.date != nil else {return true}
			guard let expireDate = self.expireDate as Date? else {return true}
			return Date() > expireDate
		}
	}
}

extension NCContact {
	var recipientType: ESI.Mail.Recipient.RecipientType? {
		guard let type = self.type else {return nil}
		return ESI.Mail.Recipient.RecipientType(rawValue: type)
	}
}

extension NCCacheLocationPickerRecent {
	enum LocationType: Int32 {
		case region = 0
		case solarSystem = 1
	}
}

/*extension NCMail {
	enum Folder: Int {
		case inbox
		case corporation
		case alliance
		case mailingList
		case sent
		case unknown
		
		var name: String {
			switch self {
			case .alliance:
				return NSLocalizedString("Alliance", comment: "")
			case .corporation:
				return NSLocalizedString("Corp", comment: "")
			case .inbox:
				return NSLocalizedString("Inbox", comment: "")
			case .mailingList:
				return NSLocalizedString("Mailing Lists", comment: "")
			case .sent:
				return NSLocalizedString("Sent", comment: "")
			case .unknown:
				return NSLocalizedString("Unknown", comment: "")
			}
		}
	}
}

*/
