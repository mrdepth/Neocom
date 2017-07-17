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

enum NCDBDgmppItemCategoryID: Int32 {
	case none = 0
	case hi
	case med
	case low
	case rig
	case subsystem
	case mode
	case charge
	case drone
	case implant
	case booster
	case ship
	case structure
	case service
	case structureDrone
	case structureRig
}

enum NCDBRegionID: Int {
	case whSpace = 11000000
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
		
		let options: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
		
		var expression = try! NSRegularExpression(pattern: "<(a[^>]*href|url)=[\"']?(.*?)[\"']?>(.*?)<\\/(a|url)>", options: options)
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.rangeAt(3)).mutableCopy() as! NSMutableAttributedString
			let url = URL(string: s.attributedSubstring(from: result.rangeAt(2)).string.replacingOccurrences(of: " ", with: ""))
			replace.addAttribute(NSLinkAttributeName, value: url!, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.rangeAt(0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "<b[^>]*>(.*?)</b>", options: options)
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.rangeAt(1)).mutableCopy() as! NSMutableAttributedString
			replace.addAttribute("UIFontDescriptorSymbolicTraits", value: CTFontSymbolicTraits.boldTrait.rawValue, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.rangeAt(0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "<i[^>]*>(.*?)</i>", options: options)
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.rangeAt(1)).mutableCopy() as! NSMutableAttributedString
			replace.addAttribute("UIFontDescriptorSymbolicTraits", value: CTFontSymbolicTraits.italicTrait.rawValue, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.rangeAt(0), with: replace)
		}

		expression = try! NSRegularExpression(pattern: "<u[^>]*>(.*?)</u>", options: options)
		
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

		expression = try! NSRegularExpression(pattern: "</?.*?>", options: options)
		
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
			if !scanner.scanHexInt32(&i) {
				exit(EXIT_FAILURE)
			}
			s.replaceCharacters(in: result.rangeAt(0), with: String(unichar(i)))
		}
		s.replaceOccurrences(of: "\\r", with: "", options: [], range: NSMakeRange(0, s.length))
		s.replaceOccurrences(of: "\\n", with: "\n", options: [], range: NSMakeRange(0, s.length))
		return String(s)
	}
}

class SQLiteDB {
	var db: OpaquePointer?
	init(filePath: String) throws {
		if sqlite3_open_v2(filePath, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
			exit(EXIT_FAILURE)
		}
	}
	
	func exec(_ sql: String, block: ([String: Any]) -> Void) throws {
		var stmt: OpaquePointer?
		if sqlite3_prepare(db, sql, Int32(sql.lengthOfBytes(using: .utf8)), &stmt, nil) != SQLITE_OK {
			exit(EXIT_FAILURE)
		}
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
					print ("Invalid SQLite type \(sqlite3_column_type(stmt, i))")
					exit(EXIT_FAILURE)
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
		exit(EXIT_FAILURE)
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
		self.iconFile = url.deletingPathExtension().lastPathComponent
		image = NCDBEveIconImage(context: context)
		image?.image = try! UIImage(contentsOf: url)
		eveIcons[factionFile] = self
	}
	
	convenience init?(typeFile: String) {
		let url = typesURL.appendingPathComponent(typeFile).appendingPathExtension("png")
		guard FileManager.default.fileExists(atPath: url.path) else {return nil}
		self.init(context: context)
		self.iconFile = url.deletingPathExtension().lastPathComponent
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

// MARK: chrFactions

print ("chrFactions")
var chrFactions = [NSNumber: NCDBChrFaction]()

try! database.exec("SELECT * FROM chrFactions") { row in
	let faction = NCDBChrFaction(context: context)
	faction.factionID = Int32(row["factionID"] as! NSNumber)
	faction.factionName = row["factionName"] as? String
	faction.icon = row["iconID"] != nil ? eveIcons[row["iconID"] as! NSNumber] : nil
	faction.race = chrRaces[row["raceIDs"] as! NSNumber]
	chrFactions[faction.factionID as NSNumber] = faction
}

// MARK: chrBloodlines

print ("chrBloodlines")
var chrBloodlines = [NSNumber: NCDBChrBloodline]()

try! database.exec("SELECT * FROM chrBloodlines") { row in
	let bloodline = NCDBChrBloodline(context: context)
	bloodline.bloodlineID = Int32(row["bloodlineID"] as! NSNumber)
	bloodline.bloodlineName = row["bloodlineName"] as? String
	bloodline.icon = row["iconID"] != nil ? eveIcons[row["iconID"] as! NSNumber] : nil
	bloodline.race = chrRaces[row["raceID"] as! NSNumber]
	chrBloodlines[bloodline.bloodlineID as NSNumber] = bloodline
}

// MARK: chrAncestries

print ("chrAncestries")
var chrAncestries = [NSNumber: NCDBChrAncestry]()

try! database.exec("SELECT * FROM chrAncestries") { row in
	let ancestry = NCDBChrAncestry(context: context)
	ancestry.ancestryID = Int32(row["ancestryID"] as! NSNumber)
	ancestry.ancestryName = row["ancestryName"] as? String
	ancestry.icon = row["iconID"] != nil ? eveIcons[row["iconID"] as! NSNumber] : nil
	ancestry.bloodline = chrBloodlines[row["bloodlineID"] as! NSNumber]
	chrAncestries[ancestry.ancestryID as NSNumber] = ancestry
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

//let defaultMetaGroup = NCDBInvMetaGroup(context: context)
//defaultMetaGroup.metaGroupID = 1000
//defaultMetaGroup.metaGroupName = ""
let defaultMetaGroup = invMetaGroups[1]

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
var invTypes = [NSNumber: NCDBInvType]()

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
	if let imageName = row["imageName"] as? String, let image = eveIcons[imageName] {
		type.icon = image
	}
	else if let iconID = row["iconID"] as? NSNumber, let icon = eveIcons[iconID] {
		type.icon = icon
	}
	
	if type.published {
		type.metaGroup = invMetaTypes[type.typeID as NSNumber] ?? defaultMetaGroup
	}
	else {
		type.metaGroup = unpublishedMetaGroup
	}
	
	var sections = [String:[String]]()
	try! database.exec("SELECT a.*, b.typeName FROM invTraits AS a LEFT JOIN invTypes as b ON a.skillID=b.typeID WHERE a.typeID = \(type.typeID) ORDER BY traitID") { row in
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
				trait = "<color=white><b>\(bonus)\(unit.displayName!)</b></color> \(bonusText)"
			}
			else {
				trait = "<color=white><b>\(Int(int))\(unit.displayName!)</b></color> \(bonusText)"
			}
		}
		else {
			trait = "<color=white><b>-</b></color> \(bonusText)"
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
	let trait = sections.sorted{return $0.key < $1.key}.map {
		return "\($0.key)\n\($0.value.joined(separator: "\n"))"
		}.joined(separator: "\n\n")
	
	var description = (row["description"] as? String)?.replacingEscapes() ?? ""
	if !trait.isEmpty {
		description += "\n\n" + trait
	}
	type.typeDescription = NCDBTxtDescription(context: context)
	type.typeDescription?.text = NSAttributedString(html: description)
	invTypes[type.typeID as NSNumber] = type
}

for (typeID, type) in invTypes {
	if let parentTypeID = invParentTypes[typeID as NSNumber] {
		type.parentType = invTypes[parentTypeID]
	}
}

// MARK: dgmAttributeCategories

print ("dgmAttributeCategories")
var dgmAttributeCategories = [NSNumber: NCDBDgmAttributeCategory]()

try! database.exec("SELECT * FROM dgmAttributeCategories") { row in
	let attributeCategory = NCDBDgmAttributeCategory(context: context)
	attributeCategory.categoryID = Int32(row["categoryID"] as! NSNumber)
	attributeCategory.categoryName = row["categoryName"] as? String
	dgmAttributeCategories[attributeCategory.categoryID as NSNumber] = attributeCategory
}

// MARK: dgmAttributeTypes

print ("dgmAttributeTypes")
var dgmAttributeTypes = [NSNumber: NCDBDgmAttributeType]()

try! database.exec("SELECT * FROM dgmAttributeTypes") { row in
	let attributeType = NCDBDgmAttributeType(context: context)
	attributeType.attributeID = Int32(row["attributeID"] as! NSNumber)
	attributeType.attributeName = row["attributeName"] as? String
	attributeType.displayName = row["displayName"] as? String
	attributeType.published = (row["published"] as! Int64) == 1
	attributeType.attributeCategory = row["categoryID"] != nil ? dgmAttributeCategories[row["categoryID"] as! NSNumber] : nil
	attributeType.icon = row["iconID"] != nil ? eveIcons[row["iconID"] as! NSNumber] : nil
	attributeType.unit = row["unitID"] != nil ? eveUnits[row["unitID"] as! NSNumber] : nil
	dgmAttributeTypes[attributeType.attributeID as NSNumber] = attributeType
}

// MARK: dgmTypeAttributes

print ("dgmTypeAttributes")

let NCDBMetaGroupAttributeID = 1692 as Int32
let NCDBMetaLevelAttributeID = 633 as Int32

try! database.exec("SELECT * FROM dgmTypeAttributes") { row in
	guard let type = invTypes[row["typeID"] as! NSNumber] else {return}
	let attributeType = dgmAttributeTypes[row["attributeID"] as! NSNumber]!
	let attribute = NCDBDgmTypeAttribute(context: context)
	attribute.type = type
	attribute.attributeType = attributeType
	attribute.value = (row["value"] as! NSNumber).floatValue
	if attributeType.attributeID == NCDBMetaGroupAttributeID {
		if let metaGroup = invMetaGroups[Int(attribute.value) as NSNumber], type.published {
			type.metaGroup = metaGroup
		}
	}
	if attributeType.attributeID == NCDBMetaLevelAttributeID {
		type.metaLevel = Int16(attribute.value)
	}
}

// MARK: dgmEffects

print ("dgmEffects")
var dgmEffects = [NSNumber: NCDBDgmEffect]()

try! database.exec("SELECT * FROM dgmEffects") { row in
	let effect = NCDBDgmEffect(context: context)
	effect.effectID = Int32(row["effectID"] as! NSNumber)
	dgmEffects[effect.effectID as NSNumber] = effect
}

// MARK: dgmTypeEffects

print ("dgmTypeEffects")

try! database.exec("SELECT * FROM dgmTypeEffects") { row in
	guard let type = invTypes[row["typeID"] as! NSNumber] else {return}
	guard let effect = dgmEffects[row["effectID"] as! NSNumber] else {return}
	effect.addToTypes(type)
}

// MARK: certMasteryLevels

print ("certMasteryLevels")
var certMasteryLevels = [NSNumber: NCDBCertMasteryLevel]()

try! database.exec("SELECT * FROM certSkills GROUP BY certLevelInt") { row in
	let level = NCDBCertMasteryLevel(context: context)
	level.level = Int16(row["certLevelInt"] as! NSNumber)
	level.displayName = row["certLevelText"] as? String
	level.icon = eveIcons["79_0\(level.level + 2)"]!
	certMasteryLevels[level.level as NSNumber] = level
}

// MARK: certCerts

print ("certCerts")
var certCerts = [NSNumber: NCDBCertCertificate]()
var certMasteries = [IndexPath: NCDBCertMastery]()

try! database.exec("SELECT * FROM certCerts") { row in
	let certificate = NCDBCertCertificate(context: context)
	certificate.certificateID = Int32(row["certID"] as! NSNumber)
	certificate.certificateName = row["name"] as? String
	certificate.group = invGroups[row["groupID"] as! NSNumber]
	certificate.certificateDescription = NCDBTxtDescription(context: context)
	certificate.certificateDescription?.text = NSAttributedString(html: (row["description"] as? String)?.replacingEscapes())
	
	for (_, level) in certMasteryLevels {
		let mastery = NCDBCertMastery(context: context)
		mastery.certificate = certificate
		mastery.level = level
		certMasteries[IndexPath(item: Int(mastery.level!.level), section: Int(certificate.certificateID))] = mastery
	}

	
	certCerts[certificate.certificateID as NSNumber] = certificate
}

// MARK: certMasteries

print ("certMasteries")

try! database.exec("SELECT * FROM certMasteries") { row in
	let certificate = certCerts[row["certID"] as! NSNumber]!
	let mastery = certMasteries[IndexPath(item: Int(row["masteryLevel"] as! NSNumber), section: Int(row["certID"] as! NSNumber))]!
	mastery.certificate?.addToTypes(invTypes[row["typeID"] as! NSNumber]!)
}

// MARK: certSkills

print ("certSkills")

try! database.exec("SELECT * FROM certSkills") { row in
	let certID = row["certID"] as! NSNumber
	let certLevel = row["certLevelInt"] as! NSNumber
	let skill = NCDBCertSkill(context: context)
	skill.mastery = certMasteries[IndexPath(item: certLevel.intValue, section: certID.intValue)]!
	skill.skillLevel = (row["skillLevel"] as! NSNumber).int16Value
	skill.type = invTypes[row["skillID"] as! NSNumber]!
}

// MARK: mapRegions

print ("mapRegions")
var mapRegions = [NSNumber: NCDBMapRegion]()

try! database.exec("SELECT * FROM mapRegions") { row in
	let region = NCDBMapRegion(context: context)
	region.regionID = Int32(row["regionID"] as! NSNumber)
	region.regionName = row["regionName"] as? String
	region.faction = row["factionID"] != nil ? chrFactions[row["factionID"] as! NSNumber] : nil
	mapRegions[region.regionID as NSNumber] = region
}

// MARK: mapConstellations

print ("mapConstellations")
var mapConstellations = [NSNumber: NCDBMapConstellation]()

try! database.exec("SELECT * FROM mapConstellations") { row in
	let constellation = NCDBMapConstellation(context: context)
	constellation.constellationID = Int32(row["constellationID"] as! NSNumber)
	constellation.constellationName = row["constellationName"] as? String
	constellation.region = mapRegions[row["regionID"] as! NSNumber]
	constellation.faction = row["factionID"] != nil ? chrFactions[row["factionID"] as! NSNumber] : nil
	mapConstellations[constellation.constellationID as NSNumber] = constellation
}

// MARK: mapSolarSystems

print ("mapSolarSystems")
var mapSolarSystems = [NSNumber: NCDBMapSolarSystem]()

try! database.exec("SELECT * FROM mapSolarSystems") { row in
	let solarSystem = NCDBMapSolarSystem(context: context)
	solarSystem.solarSystemID = Int32(row["solarSystemID"] as! NSNumber)
	solarSystem.solarSystemName = row["solarSystemName"] as? String
	solarSystem.security = Float(row["security"] as! NSNumber)
	solarSystem.constellation = mapConstellations[row["constellationID"] as! NSNumber]
	solarSystem.faction = row["factionID"] != nil ? chrFactions[row["factionID"] as! NSNumber] : nil
	mapSolarSystems[solarSystem.solarSystemID as NSNumber] = solarSystem
}

mapConstellations.values.forEach {
	guard let array = ($0.solarSystems?.allObjects as? [NCDBMapSolarSystem]), !array.isEmpty else {
		$0.security = 0
		return
	}
	$0.security = array.map {$0.security}.reduce(0, +) / Float(array.count)
	
}

mapRegions.values.forEach {
	if let array = ($0.constellations?.allObjects as? [NCDBMapConstellation])?.map ({return $0.solarSystems?.allObjects as? [NCDBMapSolarSystem] ?? []}).joined(), !array.isEmpty  {
		$0.security = array.map {$0.security}.reduce(0, +) / Float(array.count)
	}
	else {
		$0.security = 0
	}
	
	if $0.regionID >= Int32(NCDBRegionID.whSpace.rawValue) {
		$0.securityClass = -1
	}
	else {
		switch $0.security {
		case 0.5...1:
			$0.securityClass = 1
		case -1...0:
			$0.securityClass = 0
		default:
			$0.securityClass = 0.5
		}
	}
}

// MARK: mapDenormalize

print ("mapDenormalize")
var mapDenormalize = [NSNumber: NCDBMapDenormalize]()

try! database.exec("SELECT * FROM mapDenormalize WHERE groupID IN (8, 15) AND itemID NOT IN (SELECT stationID FROM staStations)") { row in
	let denormalize = NCDBMapDenormalize(context: context)
	denormalize.itemID = Int32(row["itemID"] as! NSNumber)
	denormalize.itemName = row["itemName"] as? String
	denormalize.security = Float(row["security"] as! NSNumber)
	denormalize.region = row["regionID"] != nil ? mapRegions[row["regionID"] as! NSNumber] : nil
	denormalize.constellation = row["constellationID"] != nil ? mapConstellations[row["constellationID"] as! NSNumber] : nil
	denormalize.solarSystem = row["solarSystemID"] != nil ? mapSolarSystems[row["solarSystemID"] as! NSNumber] : nil
	denormalize.type = invTypes[row["typeID"] as! NSNumber]
	mapDenormalize[denormalize.itemID as NSNumber] = denormalize
}

// MARK: staStations

print ("staStations")
var staStations = [NSNumber: NCDBStaStation]()

try! database.exec("SELECT * FROM staStations") { row in
	let station = NCDBStaStation(context: context)
	station.stationID = Int32(row["stationID"] as! NSNumber)
	station.stationName = row["stationName"] as? String
	station.security = Float(row["security"] as! NSNumber)
	station.stationType = invTypes[row["stationTypeID"] as! NSNumber]!
	station.solarSystem = row["solarSystemID"] != nil ? mapSolarSystems[row["solarSystemID"] as! NSNumber] : nil
	staStations[station.stationID as NSNumber] = station
}

// MARK: npcGroups

print ("npcGroups")
var npcGroups = [NSNumber: NCDBNpcGroup]()
var npcParentGroup = [NSNumber: NSNumber]()

try! database.exec("SELECT * FROM npcGroup") { row in
	let group = NCDBNpcGroup(context: context)
	group.npcGroupName = row["npcGroupName"] as? String
	group.group = row["groupID"] != nil ? invGroups[row["groupID"] as! NSNumber] : nil
	group.icon = row["iconName"] != nil ? eveIcons[row["iconName"] as! String] : nil
	if let parent = row["parentNpcGroupID"] as? NSNumber {
		npcParentGroup[row["npcGroupID"] as! NSNumber] = parent
	}
	npcGroups[row["npcGroupID"] as! NSNumber] = group
}

for (groupID, parentGroupID) in npcParentGroup {
	npcGroups[groupID]?.parentNpcGroup = npcGroups[parentGroupID]
}

// MARK: ramActivities

print ("ramActivities")
var ramActivities = [NSNumber: NCDBRamActivity]()

try! database.exec("SELECT * FROM ramActivities") { row in
	let activity = NCDBRamActivity(context: context)
	activity.activityID = Int32(row["activityID"] as! NSNumber)
	activity.activityName = row["activityName"] as? String
	activity.published = (row["published"] as! Int64) == 1
	activity.icon = row["iconNo"] != nil ? eveIcons[row["iconNo"] as! String] : nil
	ramActivities[activity.activityID as NSNumber] = activity
}

// MARK: ramAssemblyLineTypes

print ("ramAssemblyLineTypes")
var ramAssemblyLineTypes = [NSNumber: NCDBRamAssemblyLineType]()

try! database.exec("SELECT * FROM ramAssemblyLineTypes") { row in
	let assemblyLineType = NCDBRamAssemblyLineType(context: context)
	assemblyLineType.assemblyLineTypeID = Int32(row["assemblyLineTypeID"] as! NSNumber)
	assemblyLineType.assemblyLineTypeName = row["assemblyLineTypeName"] as? String
	assemblyLineType.baseTimeMultiplier = Float(row["baseTimeMultiplier"] as! NSNumber)
	assemblyLineType.baseMaterialMultiplier = Float(row["baseMaterialMultiplier"] as! NSNumber)
	assemblyLineType.baseCostMultiplier = Float(row["baseCostMultiplier"] as! NSNumber)
	assemblyLineType.minCostPerHour = row["minCostPerHour"] != nil ? Float(row["minCostPerHour"] as! NSNumber) : 0
	assemblyLineType.volume = Float(row["volume"] as! NSNumber)
	assemblyLineType.activity = ramActivities[row["activityID"] as! NSNumber]
	ramAssemblyLineTypes[assemblyLineType.assemblyLineTypeID as NSNumber] = assemblyLineType
}

// MARK: ramInstallationTypeContents

print ("ramInstallationTypeContents")

try! database.exec("SELECT * FROM ramInstallationTypeContents") { row in
	let installationTypeContent = NCDBRamInstallationTypeContent(context: context)
	installationTypeContent.quantity = Int32(row["quantity"] as! NSNumber)
	installationTypeContent.assemblyLineType = ramAssemblyLineTypes[row["assemblyLineTypeID"] as! NSNumber]
	installationTypeContent.installationType = invTypes[row["installationTypeID"] as! NSNumber]
}


// MARK: invTypeRequiredSkills

print ("invTypeRequiredSkills")

extension NCDBInvType {
	func getAttribute(_ attributeID: Int) -> NCDBDgmTypeAttribute? {
		return (self.attributes as? Set<NCDBDgmTypeAttribute>)?.filter {
			return $0.attributeType!.attributeID == Int32(attributeID)
			}.first
	}
}

for (_, type) in invTypes {
	for (skillID, level) in [(182, 277), (183, 278), (184, 279), (1285, 1286), (1289, 1287), (1290, 1288)] {
		if let skillID = type.getAttribute(skillID),
			let level = type.getAttribute(level),
			let skill = invTypes[Int(skillID.value) as NSNumber] {
			let requiredSkill = NCDBInvTypeRequiredSkill(context: context)
			requiredSkill.type = type
			requiredSkill.skillType = skill
			requiredSkill.skillLevel = Int16(level.value)
		}
	}
}


// MARK: industryBlueprints

print ("industryBlueprints")
var industryBlueprints = [NSNumber: NCDBIndBlueprintType]()

try! database.exec("SELECT * FROM industryBlueprints") { row in
	guard let type = invTypes[row["typeID"] as! NSNumber] else {return}
	let blueprintType = NCDBIndBlueprintType(context: context)
	blueprintType.maxProductionLimit = Int32(row["maxProductionLimit"] as! NSNumber)
	blueprintType.type = type
	industryBlueprints[blueprintType.type!.typeID as NSNumber] = blueprintType
}

// MARK: industryActivity

print ("industryActivity")
var industryActivity = [IndexPath: NCDBIndActivity]()

try! database.exec("SELECT * FROM industryActivity") { row in
	let activity = NCDBIndActivity(context: context)
	activity.time = Int32(row["time"] as! NSNumber)
	activity.blueprintType = industryBlueprints[row["typeID"] as! NSNumber]
	activity.activity = ramActivities[row["activityID"] as! NSNumber]
	industryActivity[IndexPath(item: (row["activityID"] as! NSNumber).intValue, section: (row["typeID"] as! NSNumber).intValue)] = activity
}

// MARK: industryActivityMaterials

print ("industryActivityMaterials")

try! database.exec("SELECT * FROM industryActivityMaterials") { row in
	let requiredMaterial = NCDBIndRequiredMaterial(context: context)
	requiredMaterial.quantity = Int32(row["quantity"] as! NSNumber)
	requiredMaterial.materialType = invTypes[row["materialTypeID"] as! NSNumber]
	requiredMaterial.activity = industryActivity[IndexPath(item: (row["activityID"] as! NSNumber).intValue, section: (row["typeID"] as! NSNumber).intValue)]
}

// MARK: industryActivityProducts

print ("industryActivityProducts")
var industryActivityProducts = [IndexPath: NCDBIndProduct]()

try! database.exec("SELECT * FROM industryActivityProducts") { row in
	let product = NCDBIndProduct(context: context)
	product.quantity = Int32(row["quantity"] as! NSNumber)
	product.productType = invTypes[row["productTypeID"] as! NSNumber]
	product.activity = industryActivity[IndexPath(item: (row["activityID"] as! NSNumber).intValue, section: (row["typeID"] as! NSNumber).intValue)]
	let key = IndexPath(indexes: [(row["activityID"] as! NSNumber).intValue, (row["typeID"] as! NSNumber).intValue, (row["productTypeID"] as! NSNumber).intValue])
	
	industryActivityProducts[key] = product
}

// MARK: industryActivityProbabilities

print ("industryActivityProbabilities")

try! database.exec("SELECT * FROM industryActivityProbabilities") { row in
	let key = IndexPath(indexes: [(row["activityID"] as! NSNumber).intValue, (row["typeID"] as! NSNumber).intValue, (row["productTypeID"] as! NSNumber).intValue])
	let product = industryActivityProducts[key]!
	product.probability = Float(row["probability"] as! NSNumber)

}

// MARK: industryActivitySkills

print ("industryActivitySkills")

try! database.exec("SELECT * FROM industryActivitySkills") { row in
	let requiredSkill = NCDBIndRequiredSkill(context: context)
	requiredSkill.skillLevel = Int16(row["level"] as! NSNumber)
	requiredSkill.skillType = invTypes[row["skillID"] as! NSNumber]
	requiredSkill.activity = industryActivity[IndexPath(item: (row["activityID"] as! NSNumber).intValue, section: (row["typeID"] as! NSNumber).intValue)]
}

// MARK: whTypes

print ("whTypes")

try! database.exec("SELECT * FROM invTypes WHERE groupID = 988") { row in
	let whType = NCDBWhType(context: context)
	whType.type = invTypes[row["typeID"] as! NSNumber]!
	whType.targetSystemClass = Int32(whType.type!.getAttribute(1381)?.value ?? 0)
	whType.maxStableTime = Float(whType.type!.getAttribute(1382)?.value ?? 0)
	whType.maxStableMass = Float(whType.type!.getAttribute(1383)?.value ?? 0)
	whType.maxRegeneration = Float(whType.type!.getAttribute(1384)?.value ?? 0)
	whType.maxJumpMass = Float(whType.type!.getAttribute(1385)?.value ?? 0)
}


// MARK: dgmppItems

print ("dgmppItems")

var dgmppItemGroups = [IndexPath: NCDBDgmppItemGroup]()

extension NCDBDgmppItemGroup {
	
	class func itemGroup(marketGroup: NCDBInvMarketGroup, category: NCDBDgmppItemCategory) -> NCDBDgmppItemGroup? {
		guard marketGroup.marketGroupID != 1659 else {return nil}
		let key = IndexPath(indexes: [Int(marketGroup.marketGroupID), Int(category.category), Int(category.subcategory), Int(category.race?.raceID ?? 0)])
		if let group = dgmppItemGroups[key] {
			return group
		}
		else {
			guard let group = NCDBDgmppItemGroup(marketGroup: marketGroup, category: category) else {return nil}
			dgmppItemGroups[key] = group
			return group
		}
	}
	
	convenience init?(marketGroup: NCDBInvMarketGroup, category: NCDBDgmppItemCategory) {
		var parentGroup: NCDBDgmppItemGroup?
		if let parentMarketGroup = marketGroup.parentGroup {
			parentGroup = NCDBDgmppItemGroup.itemGroup(marketGroup: parentMarketGroup, category: category)
			if parentGroup == nil {
				return nil
			}
		}
		
		self.init(context: context)
		groupName = marketGroup.marketGroupName
		icon = marketGroup.icon
		self.parentGroup = parentGroup
		self.category = category
	}
}

extension NCDBDgmppItemCategory {
	convenience init(categoryID: NCDBDgmppItemCategoryID, subcategory: Int32 = 0, race: NCDBChrRace? = nil) {
		self.init(context: context)
		self.category = categoryID.rawValue
		self.subcategory = subcategory
		self.race = race
	}
}

func compress(itemGroup: NCDBDgmppItemGroup) -> NCDBDgmppItemGroup {
	if itemGroup.subGroups?.count == 1 {
		let child = itemGroup.subGroups?.anyObject() as? NCDBDgmppItemGroup
		
		itemGroup.addToItems(child!.items!)
		itemGroup.addToSubGroups(child!.subGroups!)
		child!.removeFromItems(child!.items!)
		child!.removeFromSubGroups(child!.subGroups!)
		child?.category = nil
		child?.parentGroup = nil
		itemGroup.managedObjectContext?.delete(child!)
	}
	guard let parent = itemGroup.parentGroup else {return itemGroup}
	return compress(itemGroup: parent)
}

func trim(_ itemGroups: Set<NCDBDgmppItemGroup>) -> [NCDBDgmppItemGroup] {
	func leaf(_ itemGroup: NCDBDgmppItemGroup) -> NCDBDgmppItemGroup? {
		guard let parent = itemGroup.parentGroup else {return itemGroup}
		return leaf(parent)
	}
	
	var leaves: Set<NCDBDgmppItemGroup>? = itemGroups
	while leaves?.count == 1 {
		let leaf = leaves?.first
		if let subGroups = leaf?.subGroups as? Set<NCDBDgmppItemGroup> {
			leaves = leaf?.subGroups as? Set<NCDBDgmppItemGroup>
			leaf?.removeFromSubGroups(subGroups as NSSet)
			leaf?.category = nil
			leaf?.parentGroup = nil
			leaf?.removeFromItems(leaf!.items!)
			leaf?.managedObjectContext?.delete(leaf!)
			
		}
	}
	//print ("\(Array(leaves!).flatMap {$0.groupName} )")
	return Array(leaves ?? Set())
}

func importItems(types: [NCDBInvType], category: NCDBDgmppItemCategory, categoryName: String) {
	let groups = Set(types.flatMap { type -> NCDBDgmppItemGroup? in
		guard let marketGroup = type.marketGroup else {return nil}
		guard let group = NCDBDgmppItemGroup.itemGroup(marketGroup: marketGroup, category: category) else {return nil}
		type.dgmppItem = NCDBDgmppItem(context: context)
		group.addToItems(type.dgmppItem!)
		return group
	})
	
	let leaves = Set(groups.map { compress(itemGroup: $0) })
	
	let root = NCDBDgmppItemGroup(context: context)
	root.groupName = categoryName
	root.category = category
	let trimmed = trim(leaves)
	if trimmed.count == 0 {
		for type in types {
			type.dgmppItem?.addToGroups(root)
		}
	}
	for group in trimmed {
		group.parentGroup = root
	}
}

func importItems(category: NCDBDgmppItemCategory, categoryName: String, predicate: NSPredicate) {
	let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
	request.predicate = predicate
	let types = try! context.fetch(request)
	importItems(types: types, category: category, categoryName: categoryName)
}



func tablesFrom(conditions: [String]) -> Set<String> {
	var tables = Set<String>()
	let expression = try! NSRegularExpression(pattern: "\\b([a-zA-Z]{1,}?)\\.[a-zA-Z]{1,}?\\b", options: [.caseInsensitive])
	for condition in conditions {
		let s = condition as NSString
		for result in expression.matches(in: condition, options: [], range: NSMakeRange(0, s.length)) {
			tables.insert(s.substring(with: result.rangeAt(1)))
		}
	}
	return tables
}

importItems(category: NCDBDgmppItemCategory(categoryID: .ship), categoryName: "Ships", predicate: NSPredicate(format: "group.category.categoryID == 6"))
importItems(category: NCDBDgmppItemCategory(categoryID: .drone, subcategory: 18), categoryName: "Drones", predicate: NSPredicate(format: "group.category.categoryID == 18"))
importItems(category: NCDBDgmppItemCategory(categoryID: .drone, subcategory: 87), categoryName: "Fighters", predicate: NSPredicate(format: "group.category.categoryID == 87"))
importItems(category: NCDBDgmppItemCategory(categoryID: .structure), categoryName: "Structures", predicate: NSPredicate(format: "marketGroup.parentGroup.marketGroupID == 2199 OR marketGroup.marketGroupID == 2324"))

for subcategory in [7, 66] as [Int32] {
	importItems(category: NCDBDgmppItemCategory(categoryID: .hi, subcategory: subcategory), categoryName: "Hi Slot", predicate: NSPredicate(format: "group.category.categoryID == %d AND ANY effects.effectID == 12", subcategory))
	importItems(category: NCDBDgmppItemCategory(categoryID: .med, subcategory: subcategory), categoryName: "Med Slot", predicate: NSPredicate(format: "group.category.categoryID == %d AND ANY effects.effectID == 13", subcategory))
	importItems(category: NCDBDgmppItemCategory(categoryID: .low, subcategory: subcategory), categoryName: "Low Slot", predicate: NSPredicate(format: "group.category.categoryID == %d AND ANY effects.effectID == 11", subcategory))
	try! database.exec("select value from dgmTypeAttributes as a, dgmTypeEffects as b, invTypes as c, invGroups as d where b.effectID = 2663 AND attributeID=1547 AND a.typeID=b.typeID AND b.typeID=c.typeID AND c.groupID = d.groupID AND d.categoryID = \(subcategory) group by value;") { row in
		let value = row["value"] as! NSNumber
		importItems(category: NCDBDgmppItemCategory(categoryID: subcategory == 7 ? .rig : .structureRig, subcategory: value.int32Value), categoryName: "Rig Slot", predicate: NSPredicate(format: "group.category.categoryID == %d AND ANY effects.effectID == 2663 AND SUBQUERY(attributes, $attribute, $attribute.attributeType.attributeID == 1547 AND $attribute.value == %@).@count > 0", subcategory, value))
	}
}


try! database.exec("select raceID from invTypes as a, dgmTypeEffects as b where b.effectID = 3772 AND a.typeID=b.typeID group by raceID;") { row in
	let raceID = row["raceID"] as! NSNumber
	let race = chrRaces[raceID]
	importItems(category: NCDBDgmppItemCategory(categoryID: .subsystem, subcategory: 7, race: race), categoryName: "Subsystems", predicate: NSPredicate(format: "ANY effects.effectID == 3772 AND race.raceID == %@", raceID))
}

importItems(category: NCDBDgmppItemCategory(categoryID: .service, subcategory: 66), categoryName: "Service Slot", predicate: NSPredicate(format: "group.category.categoryID == 66 AND ANY effects.effectID == 6306"))

try! database.exec("select value from dgmTypeAttributes as a, invTypes as b where attributeID=331 and a.typeID=b.typeID and b.published = 1 group by value;") { row in
	let value = row["value"] as! NSNumber
	let request = NSFetchRequest<NCDBDgmTypeAttribute>(entityName: "DgmTypeAttribute")
	request.predicate = NSPredicate(format: "attributeType.attributeID == 331 AND value == %@", value)
	let attributes = (try! context.fetch(request))
	importItems(types: attributes.map{$0.type!}, category: NCDBDgmppItemCategory(categoryID: .implant, subcategory: value.int32Value), categoryName: "Implants")
}

try! database.exec("select value from dgmTypeAttributes as a, invTypes as b where attributeID=1087 and a.typeID=b.typeID and b.published = 1 group by value;") { row in
	let value = row["value"] as! NSNumber
	let request = NSFetchRequest<NCDBDgmTypeAttribute>(entityName: "DgmTypeAttribute")
	request.predicate = NSPredicate(format: "attributeType.attributeID == 1087 AND value == %@", value)
	let attributes = (try! context.fetch(request))
	importItems(types: attributes.map{$0.type!}, category: NCDBDgmppItemCategory(categoryID: .booster, subcategory: value.int32Value), categoryName: "Boosters")
}

try! database.exec("SELECT typeID FROM dgmTypeAttributes WHERE attributeID=10000") { row in
	let typeID = row["typeID"] as! NSNumber
	let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
	request.predicate = NSPredicate(format: "ANY effects.effectID == 10002 AND SUBQUERY(attributes, $attribute, $attribute.attributeType.attributeID == 1302 AND $attribute.value == %@).@count > 0", typeID)
	let root = NCDBDgmppItemGroup(context: context)
	root.category = NCDBDgmppItemCategory(categoryID: .mode, subcategory: typeID.int32Value)
	root.groupName = "Tactical Mode"
	for type in try! context.fetch(request) {
		type.dgmppItem = NCDBDgmppItem(context: context)
		root.addToItems(type.dgmppItem!)
	}
}


var chargeCategories = [IndexPath: NCDBDgmppItemCategory]()
let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
let attributeIDs = Set<Int32>([604, 605, 606, 609, 610])
request.predicate = NSPredicate(format: "ANY attributes.attributeType.attributeID IN (%@)", attributeIDs)
for type in try! context.fetch(request) {
	let attributes = type.attributes?.allObjects as? [NCDBDgmTypeAttribute]
	let chargeSize = attributes?.first(where: {$0.attributeType?.attributeID == 128})?.value
	var chargeGroups: Set<Int> = Set()
	for attribute in attributes?.filter({attributeIDs.contains($0.attributeType!.attributeID)}) ?? [] {
		chargeGroups.insert(Int(attribute.value))
	}
	
	if !chargeGroups.isEmpty {
		var array = chargeGroups.sorted()
		if let chargeSize = chargeSize {
			array.append(Int(chargeSize))
		}
		else {
			array.append(Int(type.capacity * 100))
		}
		let key = IndexPath(indexes: array)
		if let category = chargeCategories[key] {
			type.dgmppItem?.charge = category
		}
		else {
			let root = NCDBDgmppItemGroup(context: context)
			root.groupName = "Ammo"
			root.category = NCDBDgmppItemCategory(categoryID: .charge, subcategory: Int32(chargeSize ?? 0), race: nil)
			type.dgmppItem?.charge = root.category
			chargeCategories[key] = root.category!
			
			let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
			if let chargeSize = chargeSize {
				request.predicate = NSPredicate(format: "group.groupID IN %@ AND published = 1 AND SUBQUERY(attributes, $attribute, $attribute.attributeType.attributeID == 128 AND $attribute.value == %d).@count > 0", chargeGroups, Int(chargeSize))
			}
			else {
				request.predicate = NSPredicate(format: "group.groupID IN %@ AND published = 1 AND volume < %f", chargeGroups, type.capacity)
			}
			for charge in try! context.fetch(request) {
				if charge.dgmppItem == nil {
					charge.dgmppItem = NCDBDgmppItem(context: context)
				}
				root.addToItems(charge.dgmppItem!)
				//charge.dgmppItem?.addToGroups(root)
			}
		}

	}
}

print ("dgmppItems info")
request.predicate = NSPredicate(format: "dgmppItem <> NULL")
for type in try! context.fetch(request) {
	switch NCDBDgmppItemCategoryID(rawValue: (type.dgmppItem!.groups!.anyObject() as! NCDBDgmppItemGroup).category!.category)! {
	case .hi, .med, .low, .rig, .structureRig:
		type.dgmppItem?.requirements = NCDBDgmppItemRequirements(context: context)
		type.dgmppItem?.requirements?.powerGrid = type.getAttribute(30)?.value ?? 0
		type.dgmppItem?.requirements?.cpu = type.getAttribute(50)?.value ?? 0
		type.dgmppItem?.requirements?.calibration = type.getAttribute(1153)?.value ?? 0
	case .charge, .drone, .structureDrone:
		var multiplier = max(type.getAttribute(64)?.value ?? 0, type.getAttribute(212)?.value ?? 0)
		if multiplier == 0 {
			multiplier = 1
		}
		let em = (type.getAttribute(114)?.value ?? 0) * multiplier
		let kinetic = (type.getAttribute(117)?.value ?? 0) * multiplier
		let thermal = (type.getAttribute(118)?.value ?? 0) * multiplier
		let explosive = (type.getAttribute(116)?.value ?? 0) * multiplier
		if em + kinetic + thermal + explosive > 0 {
			type.dgmppItem?.damage = NCDBDgmppItemDamage(context: context)
			type.dgmppItem?.damage?.emAmount = em
			type.dgmppItem?.damage?.kineticAmount = kinetic
			type.dgmppItem?.damage?.thermalAmount = thermal
			type.dgmppItem?.damage?.explosiveAmount = explosive
		}
	case .ship:
		type.dgmppItem?.shipResources = NCDBDgmppItemShipResources(context: context)
		type.dgmppItem?.shipResources?.hiSlots = Int16(type.getAttribute(14)?.value ?? 0)
		type.dgmppItem?.shipResources?.medSlots = Int16(type.getAttribute(13)?.value ?? 0)
		type.dgmppItem?.shipResources?.lowSlots = Int16(type.getAttribute(12)?.value ?? 0)
		type.dgmppItem?.shipResources?.rigSlots = Int16(type.getAttribute(1137)?.value ?? 0)
		type.dgmppItem?.shipResources?.turrets = Int16(type.getAttribute(102)?.value ?? 0)
		type.dgmppItem?.shipResources?.launchers = Int16(type.getAttribute(101)?.value ?? 0)
	case .structure:
		type.dgmppItem?.structureResources = NCDBDgmppItemStructureResources(context: context)
		type.dgmppItem?.structureResources?.hiSlots = Int16(type.getAttribute(14)?.value ?? 0)
		type.dgmppItem?.structureResources?.medSlots = Int16(type.getAttribute(13)?.value ?? 0)
		type.dgmppItem?.structureResources?.lowSlots = Int16(type.getAttribute(12)?.value ?? 0)
		type.dgmppItem?.structureResources?.rigSlots = Int16(type.getAttribute(1137)?.value ?? 0)
		type.dgmppItem?.structureResources?.serviceSlots = Int16(type.getAttribute(2056)?.value ?? 0)
		type.dgmppItem?.structureResources?.turrets = Int16(type.getAttribute(102)?.value ?? 0)
		type.dgmppItem?.structureResources?.launchers = Int16(type.getAttribute(101)?.value ?? 0)
	default:
		break
	}
}

print ("dgmppHullTypes")

do {
	func types(_ marketGroup: NCDBInvMarketGroup) -> [NCDBInvType] {
		var array = (marketGroup.types?.allObjects as? [NCDBInvType]) ?? []
		for group in marketGroup.subGroups?.allObjects ?? [] {
			array.append(contentsOf: types(group as! NCDBInvMarketGroup))
		}
		return array
	}
	
	for marketGroup in invMarketGroups[4]?.subGroups ?? [] {
		let marketGroup = marketGroup as! NCDBInvMarketGroup
		let hullType = NCDBDgmppHullType(context: context)
		hullType.hullTypeName = marketGroup.marketGroupName
		
		let ships = Set(types(marketGroup))
		hullType.addToTypes(ships as NSSet)
		
		let array = ships.flatMap {$0.getAttribute(552)?.value}.map{ Double($0) }
		var signature = array.reduce(0, +)
		signature /= Double(array.count)
		signature = ceil(signature / 5) * 5
		
		hullType.signature = Float(signature)
	}
	
}


print ("Save...")
try! context.save()
