//
//  main.swift
//  NCDatabase
//
//  Created by Artem Shimanski on 16.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Cocoa
import CoreText

public typealias UIImage = Data

class NCDBImageValueTransformer: ValueTransformer {
	override func reverseTransformedValue(_ value: Any?) -> Any? {
		return value
	}
}

ValueTransformer.setValueTransformer(NCDBImageValueTransformer(), forName: NSValueTransformerName("NCDBImageValueTransformer"))

extension NSColor {
	
	public convenience init(number: UInt) {
		var n = number
		var abgr = [CGFloat]()
		
		for _ in 0...3 {
			let byte = n & 0xFF
			abgr.append(CGFloat(byte) / 255.0)
			n >>= 8
		}
		
		self.init(red: abgr[3], green: abgr[2], blue: abgr[1], alpha: abgr[0])
	}
	
	public convenience init?(string: String) {
		let scanner = Scanner(string: string)
		var rgba: UInt32 = 0
		if scanner.scanHexInt32(&rgba) {
			self.init(number:UInt(rgba))
		}
		else {
			let key = string.capitalized
			for colorList in NSColorList.availableColorLists() {
				guard let color = colorList.color(withKey: key) else {continue}
				self.init(cgColor: color.cgColor)
				return
			}
		}
		return nil
	}
}

extension NSAttributedString {
	convenience init(html: String?) {
		var html = html ?? ""
		html = html.replacingOccurrences(of: "<br>", with: "\n", options: [.caseInsensitive], range: nil)
		html = html.replacingOccurrences(of: "<p>", with: "\n", options: [.caseInsensitive], range: nil)
		
		let s = NSMutableAttributedString(string: html)
		
		var expression = try! NSRegularExpression(pattern: "<(a[^>]*href|url)=[\"']?(.*?)[\"']?>(.*?)<\\/(a|url)>", options: [.caseInsensitive])
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.rangeAt(3)).mutableCopy() as! NSMutableAttributedString
			let url = URL(string: s.attributedSubstring(from: result.rangeAt(2)).string.replacingOccurrences(of: " ", with: ""))
			replace.addAttribute("NSURL", value: url!, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.rangeAt(0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "<b[^>]*>(.*?)</b>", options: [.caseInsensitive])
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.rangeAt(1)).mutableCopy() as! NSMutableAttributedString
			replace.addAttribute("UIFontDescriptorSymbolicTraits", value: CTFontSymbolicTraits.boldTrait.rawValue, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.rangeAt(0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "<i[^>]*>(.*?)</i>", options: [.caseInsensitive])
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.rangeAt(1)).mutableCopy() as! NSMutableAttributedString
			replace.addAttribute("UIFontDescriptorSymbolicTraits", value: CTFontSymbolicTraits.italicTrait.rawValue, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.rangeAt(0), with: replace)
		}

		expression = try! NSRegularExpression(pattern: "<u[^>]*>(.*?)</u>", options: [.caseInsensitive])
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.rangeAt(1)).mutableCopy() as! NSMutableAttributedString
			replace.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.rangeAt(0), with: replace)
		}

		expression = try! NSRegularExpression(pattern: "<(color|font)[^>]*=[\"']?(.*?)[\"']?\\s*?>(.*?)</(color|font)>", options: [.caseInsensitive])
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let key = s.attributedSubstring(from: result.rangeAt(2)).string
			let replace = s.attributedSubstring(from: result.rangeAt(3)).mutableCopy() as! NSMutableAttributedString
			if let color = NSColor(string: key) {
				replace.addAttribute(NSForegroundColorAttributeName, value: color, range: NSMakeRange(0, replace.length))
			}
			s.replaceCharacters(in: result.rangeAt(0), with: replace)
		}

		expression = try! NSRegularExpression(pattern: "</?.*?>", options: [.caseInsensitive])
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			s.replaceCharacters(in: result.rangeAt(0), with: NSAttributedString(string: ""))
		}
		
		self.init(attributedString: s)
	}
}

extension String {
	static let regex = try! NSRegularExpression(pattern: "\\\\u(.{4})", options: [.caseInsensitive])
	func replacingEscapes() -> String {
		let s = NSMutableString(string: self)
		for result in String.regex.matches(in: self, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let hexString = s.substring(with: result.rangeAt(1))
			let scanner = Scanner(string: hexString)
			var i: UInt32 = 0
			assert(scanner.scanHexInt32(&i))
			s.replaceCharacters(in: result.rangeAt(0), with: String(unichar(i)))
		}
		return String(s)
	}
}

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
let factionsURL = URL(fileURLWithPath: args["-factions"]!)
try? FileManager.default.removeItem(at: out)

let managedObjectModel = NSManagedObjectModel.mergedModel(from: nil)!
let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: out, options: [NSSQLitePragmasOption:["journal_mode": "OFF"]])
let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
context.persistentStoreCoordinator = persistentStoreCoordinator


// MARK: eveIcons

print ("eveIcons")
var eveIcons = [AnyHashable: NCDBEveIcon]()

extension NCDBEveIcon {
	convenience init?(iconFile: String) {
		let url = iconsURL.appendingPathComponent(iconFile).appendingPathExtension("png")
		guard FileManager.default.fileExists(atPath: url.path) else {return nil}
		self.init(context: context)
		self.iconFile = iconFile
		image = NCDBEveIconImage(context: context)
		image?.image = try! UIImage(contentsOf: url)
		eveIcons[iconFile] = self
	}
	
	convenience init?(factionFile: String) {
		let url = factionsURL.appendingPathComponent(factionFile)
		guard FileManager.default.fileExists(atPath: url.path) else {return nil}
		self.init(context: context)
		self.iconFile = factionsURL.deletingPathExtension().lastPathComponent
		image = NCDBEveIconImage(context: context)
		image?.image = try! UIImage(contentsOf: url)
		eveIcons[factionFile] = self
	}
	
	convenience init?(typeFile: String) {
		let url = typesURL.appendingPathComponent(typeFile).appendingPathExtension("png")
		guard FileManager.default.fileExists(atPath: url.path) else {return nil}
		self.init(context: context)
		self.iconFile = factionsURL.deletingPathExtension().lastPathComponent
		image = NCDBEveIconImage(context: context)
		image?.image = try! UIImage(contentsOf: url)
		eveIcons[typeFile] = self
	}
}


try! database.exec("select * from eveIcons") { row in
	let iconFile = row["iconFile"] as! String
	guard let icon = NCDBEveIcon(iconFile: iconFile) else {return}
	eveIcons[row["iconID"] as! NSNumber] = icon
}

for iconFile in ["09_07", "105_32", "50_13", "38_193", "38_194", "38_195", "38_174", "17_04", "74_14", "23_03", "18_02", "33_02", "79_01", "79_02", "79_03", "79_04", "79_05", "79_06"] {
	var eveIcon: [String: Any]?
	try! database.exec("SELECT * FROM eveIcons WHERE iconFile == \"\(iconFile)\"") { row in
		eveIcon = row
	}
	if eveIcon != nil {
		continue
	}
	guard let _ = NCDBEveIcon(iconFile: iconFile) else {
		print ("Warning: icon not found \"\(iconFile)\"")
		continue
	}
}

try! database.exec("SELECT * FROM ramActivities") { row in
	guard let iconNo = row["iconNo"] as? String else {return}
	if eveIcons[iconNo] == nil {
		guard let _ = NCDBEveIcon(iconFile: iconNo) else {
			print ("Warning: icon not found \"\(iconNo)\"")
			return
		}
	}
}

try! database.exec("SELECT * FROM npcGroup WHERE iconName IS NOT NULL GROUP BY iconName") { row in
	guard let iconName = row["iconName"] as? String else {return}
	if eveIcons[iconName] == nil {
		guard let _ = NCDBEveIcon(factionFile: iconName) else {
			print ("Warning: icon not found \"\(iconName)\"")
			return
		}
	}
}

try! database.exec("SELECT * FROM invTypes WHERE imageName IS NOT NULL GROUP BY imageName") { row in
	guard let imageName = row["imageName"] as? String else {return}
	if eveIcons[imageName] == nil {
		guard let _ = NCDBEveIcon(typeFile: imageName) else {
			print ("Warning: icon not found \"\(imageName)\"")
			return
		}
	}
}

// MARK: eveUnits

print ("eveUnits")
var eveUnits = [NSNumber: NCDBEveUnit]()

try! database.exec("SELECT * FROM eveUnits") { row in
	let unit = NCDBEveUnit(context: context)
	unit.unitID = Int32(row["unitID"] as! NSNumber)
	unit.displayName = row["displayName"] as? String
	eveUnits[row["unitID"] as! NSNumber] = unit
}

// MARK: chrRaces

print ("chrRaces")
var chrRaces = [NSNumber: NCDBChrRace]()

try! database.exec("SELECT * FROM chrRaces") { row in
	let race = NCDBChrRace(context: context)
	race.raceID = Int32(row["raceID"] as! NSNumber)
	race.raceName = row["raceName"] as? String
	race.icon = row["iconID"] != nil ? eveIcons[row["iconID"] as! NSNumber] : nil
	chrRaces[race.raceID as NSNumber] = race
}

// MARK: invCategories

print ("invCategories")
var invCategories = [NSNumber: NCDBInvCategory]()

try! database.exec("SELECT * FROM invCategories") { row in
	let category = NCDBInvCategory(context: context)
	category.categoryID = Int32(row["categoryID"] as! NSNumber)
	category.categoryName = row["categoryName"] as? String
	category.published = (row["published"] as! NSNumber) == 1
	category.icon = row["iconID"] != nil ? eveIcons[row["iconID"] as! NSNumber] : nil
	invCategories[category.categoryID as NSNumber] = category
}

// MARK: invGroups

print ("invGroups")
var invGroups = [NSNumber: NCDBInvGroup]()

try! database.exec("SELECT * FROM invGroups") { row in
	let group = NCDBInvGroup(context: context)
	group.groupID = Int32(row["groupID"] as! NSNumber)
	group.groupName = row["groupName"] as? String
	group.published = (row["published"] as! NSNumber) == 1
	group.category = invCategories[row["categoryID"] as! NSNumber]
	group.icon = row["iconID"] != nil ? eveIcons[row["iconID"] as! NSNumber] : nil
	invGroups[group.groupID as NSNumber] = group
}

// MARK: invMarketGroups

print ("invMarketGroups")
var invMarketGroups = [NSNumber: NCDBInvMarketGroup]()
var marketGroupsParent = [NSNumber: NSNumber]()
try! database.exec("SELECT * FROM invMarketGroups") { row in
	let marketGroup = NCDBInvMarketGroup(context: context)
	marketGroup.marketGroupID = Int32(row["marketGroupID"] as! NSNumber)
	marketGroup.marketGroupName = row["marketGroupName"] as? String
	marketGroup.icon = row["iconID"] != nil ? eveIcons[row["iconID"] as! NSNumber] : nil
	if let parentGroupID = row["parentGroupID"] as? NSNumber {
		marketGroupsParent[marketGroup.marketGroupID as NSNumber] = parentGroupID
	}
	invMarketGroups[marketGroup.marketGroupID as NSNumber] = marketGroup
}
for (groupID, parentID) in marketGroupsParent {
	invMarketGroups[groupID]?.parentGroup = invMarketGroups[parentID]
}

// MARK: invMetaGroups

print ("invMetaGroups")
var invMetaGroups = [NSNumber: NCDBInvMetaGroup]()

try! database.exec("SELECT * FROM invMetaGroups") { row in
	let metaGroup = NCDBInvMetaGroup(context: context)
	metaGroup.metaGroupID = Int32(row["metaGroupID"] as! NSNumber)
	metaGroup.metaGroupName = row["metaGroupName"] as? String
	metaGroup.icon = row["iconID"] != nil ? eveIcons[row["iconID"] as! NSNumber] : nil
	invMetaGroups[metaGroup.metaGroupID as NSNumber] = metaGroup
}

let defaultMetaGroup = NCDBInvMetaGroup(context: context)
defaultMetaGroup.metaGroupID = 1000
defaultMetaGroup.metaGroupName = ""

let unpublishedMetaGroup = NCDBInvMetaGroup(context: context)
unpublishedMetaGroup.metaGroupID = 1001
unpublishedMetaGroup.metaGroupName = "Unpublished"


// MARK: invMetaTypes

print ("invMetaTypes")
var invMetaTypes = [NSNumber: NCDBInvMetaGroup]()
var invParentTypes = [NSNumber: NSNumber]()

try! database.exec("SELECT * FROM invMetaTypes") { row in
	let typeID = row["typeID"] as! NSNumber
	invMetaTypes[typeID] = invMetaGroups[row["metaGroupID"] as! NSNumber]
	if let parentType = row["parentTypeID"] as? NSNumber {
		invParentTypes[typeID] = parentType
	}
}

// MARK: invTypes

print ("invTypes")
var invTypes = [AnyHashable: NCDBInvType]()

try! database.exec("SELECT * FROM invTypes") { row in
	let type = NCDBInvType(context: context)
	type.typeID = Int32(row["typeID"] as! NSNumber)
	type.basePrice = Float(row["basePrice"] as! NSNumber)
	type.capacity = Float(row["capacity"] as! NSNumber)
	type.mass = Float(row["mass"] as! NSNumber)
	type.portionSize = Float(row["portionSize"] as! NSNumber)
	type.group = invGroups[row["groupID"] as! NSNumber]
	type.published = (row["published"] as! Int64) == 1 && type.group!.published
	type.radius = row["radius"] != nil ? Float(row["radius"] as! NSNumber) : 0
	type.volume = row["volume"] != nil ? Float(row["volume"] as! NSNumber) : 0
	type.marketGroup = row["marketGroupID"] != nil ? invMarketGroups[row["marketGroupID"] as! NSNumber] : nil
	type.race = row["raceID"] != nil ? chrRaces[row["raceID"] as! NSNumber] : nil
	type.typeName = (row["typeName"] as! String).replacingEscapes()
	type.metaGroup = type.published ? defaultMetaGroup : unpublishedMetaGroup
	
	var sections = [String:[String]]()
	try! database.exec("SELECT a.*, b.typeName FROM invTraits AS a, invTypes AS b WHERE a.typeID = \(type.typeID) AND a.skillID=b.typeID ORDER BY traitID") { row in
		let skillID = row["skillID"] as? NSNumber
		let skillName = row["typeName"] as? String
		let typeID = row["typeID"] as! NSNumber
		let bonus = row["bonus"] as? NSNumber
		let bonusText = row["bonusText"] as! String
		let unitID = row["unitID"] as? NSNumber
		
		let trait: String
		if let bonus = bonus?.doubleValue, let unitID = unitID, let unit = eveUnits[unitID] {
			var int: Double = 0
			if modf(bonus, &int) != 0 {
				trait = "<color=caption><b>\(bonus)\(unit.displayName!)</b></color> \(bonusText)"
			}
			else {
				trait = "<color=caption><b>\(Int(int))\(unit.displayName!)</b></color> \(bonusText)"
			}
		}
		else {
			trait = "<color=caption><b>-</b></color> \(bonusText)"
		}
		
		let section: String
		if let skillName = skillName, let skillID = skillID?.intValue {
			section = "<a href=showinfo:\(skillID)>\(skillName)</a> bonuses (per skill level):"
		}
		else {
			section = "<b>Role Bonus</b>:"
		}
		var array = sections[section] ?? []
		array.append(trait)
		sections[section] = array
	}
	sections.sorted{return $0.key > $1.key}.map {
		return $0.key
	}
	
	let trait = sections.sorted{return $0.key > $1.key}.map {
		let trait = $0.value.joined(separator: ",")
		return "\($0.key)\n\(trait)"
	}
	
	
	for key in sections.keys.sorted() {
		trait.append("\(key)\n")
		trait.append("\(sections[key]!.joined(separator: "\n"))")
	}
	if !trait.isEmpty {
		print ("\(trait)")
	}
}
