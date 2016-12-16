//
//  main.swift
//  NCDatabase
//
//  Created by Artem Shimanski on 16.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Cocoa

public typealias UIImage = NSImage

class SQLiteDB {
	var db: OpaquePointer?
	init(filePath: String) throws {
		assert(sqlite3_open_v2(filePath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK)
	}
	
	func exec(_ sql: String, block: ([String: Any]) -> Void) throws {
		var stmt: OpaquePointer?
		assert(sqlite3_prepare(db, sql, Int32(sql.lengthOfBytes(using: .utf8)), &stmt, nil) == SQLITE_OK)
		
		while sqlite3_step(stmt) == SQLITE_ROW {
			let n = sqlite3_column_count(stmt)
			var dic = [String: Any]()
			for i in 0..<n {
				let name = String(cString: sqlite3_column_name(stmt, i))
				switch sqlite3_column_type(stmt, i) {
				case SQLITE_INTEGER:
					let int = sqlite3_column_int64(stmt, i)
					dic[name] = int
				case SQLITE_FLOAT:
					let double = sqlite3_column_double(stmt, i)
					dic[name] = double
				case SQLITE_BLOB:
					let size = sqlite3_column_bytes(stmt, i)
					if let blob = sqlite3_column_blob(stmt, i) {
						let data = Data(bytes: blob, count: Int(size))
						if data.count > 0 {
							dic[name] = data
						}
					}
				case SQLITE_NULL:
					break
				case SQLITE_TEXT:
					let text = String(cString: sqlite3_column_text(stmt, i))
					if !text.isEmpty {
						dic[name] = text
					}
				default:
					assert(false, "Invalid SQLite type \(sqlite3_column_type(stmt, i))")
					break
				}
			}
			block(dic)
		}
		sqlite3_finalize(stmt)
	}
}

var args = [String: String]()

var key: String?
for arg in CommandLine.arguments[1..<CommandLine.arguments.count] {
	if arg.hasPrefix("-") {
		key = arg
	}
	else if let k = key {
		args[k] = arg
		key = nil
	}
	else {
		assert(false)
	}
}

let sde = args["-sde"]!
let database = try! SQLiteDB(filePath: sde)
let out = URL(fileURLWithPath: args["-out"]!)
let iconsURL = URL(fileURLWithPath: args["-icons"]!)
let typesURL = URL(fileURLWithPath: args["-types"]!)
try? FileManager.default.removeItem(at: out)

let managedObjectModel = NSManagedObjectModel.mergedModel(from: nil)!
let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: out, options: [NSSQLitePragmasOption:["journal_mode": "OFF"]])
let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator


// MARK: eveIcons

extension URL {
	init?(iconResource: String) {
		guard let fileName = URL(string: iconResource)?.lastPathComponent else {return nil}
		let url = iconsURL.appendingPathComponent("items").appendingPathComponent(fileName)
		guard FileManager.default.fileExists(atPath: url.path) else {return nil}
		self = url
	}
	var iconFile: String {
		get {
			let fileName = self.deletingPathExtension().lastPathComponent as NSString
			let regex = try! NSRegularExpression(pattern: "(\\d*?)_(\\d*?)_(\\d*)$", options: [])
			if let result = regex.firstMatch(in: fileName as String, options: [], range: NSMakeRange(0, fileName.length)) {
				let a = (fileName.substring(with: result.rangeAt(1)) as NSString).integerValue
				let b = (fileName.substring(with: result.rangeAt(3)) as NSString).integerValue
				return String(format: "%.2d_%.2d", a, b)
			}
			else {
				return fileName as String
			}
		}
	}
}

try! database.exec("select * from eveIcons") { row in
	let iconFile = row["iconFile"] as! String
	guard let url = URL(iconResource: iconFile) else {return}
	print ("\(url.iconFile)\t")
}
