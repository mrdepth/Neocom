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
		ValueTransformer.setValueTransformer(NCSecureUnarchiver(), forName: NSValueTransformerName("NCSecureUnarchiver"))
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
	
	func store<T>(_ object: T?, forKey key: String, account: String?, date: Date?, expireDate: Date?, error: Error?, completionHandler: ((NCCacheRecord?) -> Void)?) {
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
				record!.set(object)
				record!.date = date ?? Date()
				record!.expireDate = expireDate ?? record!.expireDate ?? record!.date!.addingTimeInterval(3) as Date?
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
	
	/*func store(_ data: Data?, forKey key: String, account: String?, date: Date?, expireDate: Date?, error: Error?, completionHandler: ((NCCacheRecord?) -> Void)?) {
		performBackgroundTask { (managedObjectContext) in
			var record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)))?.last
			if record == nil {
				
				let r = NCCacheRecord(entity: NSEntityDescription.entity(forEntityName: "Record", in: managedObjectContext)!, insertInto: managedObjectContext)
				r.account = account
				r.key = key
				r.data = NCCacheRecordData(entity: NSEntityDescription.entity(forEntityName: "RecordData", in: managedObjectContext)!, insertInto: managedObjectContext)
				record = r
			}
			if data != nil || record!.data!.data == nil {
				record!.data?.data = data
				record!.date = date ?? Date()
				record!.expireDate = expireDate ?? record!.expireDate ?? record!.date!.addingTimeInterval(3) as Date?
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
	}*/
	
	//MARK: Private
	
	@objc func managedObjectContextDidSave(_ notification: Notification) {
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
	class func fetchRequest(forKey key: String?, account: String?) -> NSFetchRequest<NCCacheRecord> {
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
	
	var locationTypeDisplayName: String? {
		switch LocationType(rawValue: self.locationType) {
		case .region?:
			return NSLocalizedString("Regions", comment: "")
		case .solarSystem?:
			return NSLocalizedString("Solar Systems", comment: "")
		default:
			return nil
		}
	}
}

class NCSecureUnarchiver: ValueTransformer {
	override func transformedValue(_ value: Any?) -> Any? {
		guard let value = value else {return nil}
		return NSKeyedArchiver.archivedData(withRootObject: value)
	}
	
	override func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let data = value as? Data else {return nil}
		do {
			let result = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
			return result
		}
		catch {
			return nil
		}
	}
}

extension NCCacheRecord {
	func get<T: Decodable>() -> T? {
		guard let data = self.data?.data else {return nil}
		return try? JSONDecoder().decode(T.self, from: data)
	}
	func set<T: Encodable>(_ value: T?) {
		if let value = value {
			guard let data = try? JSONEncoder().encode(value) else {return}
			self.data?.data = data
		}
		else {
			data?.data = nil
		}
	}
	
	func get() -> UIImage? {
		guard let data = self.data?.data else {return nil}
		return UIImage(data: data)
	}
	func set(_ value: UIImage?) {
		if let value = value {
			guard let data = UIImagePNGRepresentation(value) else {return}
			self.data?.data = data
		}
		else {
			data?.data = nil
		}
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
