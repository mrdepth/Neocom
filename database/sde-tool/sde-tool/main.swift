//
//  main.swift
//  sde-tool
//
//  Created by Artem Shimanski on 13.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

func parseSequence(_ parser: UnsafeMutablePointer<yaml_parser_t>) -> String {
	var values: [String] = []
	sequence(first: parseValue(parser), next: { i in return parseValue(parser) }).flatMap{$0}.forEach { values.append($0) }
	return "[\(values.joined(separator: ","))]"
}

func parseMapping(_ parser: UnsafeMutablePointer<yaml_parser_t>) -> String {
	var event = yaml_event_t()
	
	var values: [String] = []
	
	repeat {
		guard yaml_parser_parse(parser, &event) != 0 else {return ""}
		defer {yaml_event_delete(&event)}
		
		switch event.type {
		case YAML_SCALAR_EVENT:
			let value = event.data.scalar.value
			let length = event.data.scalar.length
			let key = String(bytesNoCopy: value!, length: length, encoding: .utf8, freeWhenDone: false)!
			values.append("\"\(key)\":\(parseValue(parser)!)")
		case YAML_MAPPING_END_EVENT:
			return "{\(values.joined(separator: ","))}"
		default:
			return ""
		}
	}
	while (true)
}

func parseValue(_ parser: UnsafeMutablePointer<yaml_parser_t>) -> String? {
	var event = yaml_event_t()
	guard yaml_parser_parse(parser, &event) != 0 else {return ""}
	defer {yaml_event_delete(&event)}

	switch event.type {
	case YAML_SCALAR_EVENT:
		let value = event.data.scalar.value
		let length = event.data.scalar.length
		let s = String(bytesNoCopy: value!, length: length, encoding: .utf8, freeWhenDone: false)!
		return "\"\(s)\""
	case YAML_MAPPING_START_EVENT:
		return parseMapping(parser)
	case YAML_SEQUENCE_START_EVENT:
		return parseSequence(parser)
	case YAML_SEQUENCE_END_EVENT:
		return nil
	case YAML_STREAM_START_EVENT, YAML_DOCUMENT_START_EVENT:
		return parseValue(parser)
	default:
		return nil
	}
}

enum State {
	case sequence
	case mapping
	case key
	case value
}
var stack: [State] = []

var parser = yaml_parser_t()

enum Container {
	case document
	case sequence
	case mapping
	case keyPair
}

let s = try! Data(contentsOf: URL(fileURLWithPath: "/Users/shimanski/Documents/git/EVEUniverse/dbTools/dbinit/input/sde/fsd/categoryIDs.yaml"))
var output = ""

s.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Void in
	yaml_parser_initialize(&parser)
	defer {yaml_parser_delete(&parser)}
	yaml_parser_set_input_string(&parser, ptr, s.count)
	
	var stack = [Container]()
	stack.append(.document)
	
	var event = yaml_event_t()
	var last = YAML_NO_EVENT
	repeat {
		guard yaml_parser_parse(&parser, &event) != 0 else {break}
		defer {yaml_event_delete(&event)}
		
		switch event.type {
		case YAML_STREAM_END_EVENT:
			return
		case YAML_SCALAR_EVENT:
			let value = event.data.scalar.value
			let length = event.data.scalar.length
			let s = String(bytesNoCopy: value!, length: length, encoding: .utf8, freeWhenDone: false)!
			
			let v: Any = Int(s) ?? Double(s) ?? "\"\(s)\""

			switch stack.last {
			case .sequence?:
				if last != YAML_SEQUENCE_START_EVENT {
					output.append(",")
				}
				output.append("\(v)")
			case .mapping?:
				if last != YAML_MAPPING_START_EVENT {
					output.append(",")
				}
				output.append("\"\(s)\":")
				stack.append(.keyPair)
			case .keyPair?:
				output.append("\(v)")
				stack.removeLast()
			default:
				break
			}
			break
		case YAML_SEQUENCE_START_EVENT:
			output.append("[")
			stack.append(.sequence)
		case YAML_SEQUENCE_END_EVENT:
			output.append("]")
			stack.removeLast()
			if stack.last == .keyPair {
				stack.removeLast()
			}
		case YAML_MAPPING_START_EVENT:
			output.append("{")
			stack.append(.mapping)
		case YAML_MAPPING_END_EVENT:
			output.append("}")
			stack.removeLast()
			if stack.last == .keyPair {
				stack.removeLast()
			}
		default:
			break
		}
		last = event.type
	}
	while (true)
	
	
	
//	let json = parseValue(&parser)
//	print(json!)
}

print("\(output)")
let root = CommandLine.arguments[1]

enum DumpError: Error {
	case fileNotFound
	case schemaIsInvalid(String)
}

extension NSArray {
	func validate(keyPath: String, with: NSArray) throws {
		for (i, value1) in enumerated() {
			switch (value1, with[i]) {
			case let (dic1 as NSDictionary, dic2 as NSDictionary):
				try dic1.validate(keyPath: keyPath, with: dic2)
			case let (arr1 as NSArray, arr2 as NSArray):
				try arr1.validate(keyPath: keyPath, with: arr2)
			case let (obj1 as Double, obj2 as Double) where obj1.distance(to: obj2) < 0.00001:
				break
			case let (obj1 as NSObject, obj2 as NSObject) where obj1.isEqual(obj2):
				break
			default:
				throw DumpError.schemaIsInvalid("keyPath")
			}
		}
	}
}

extension NSDictionary {
	func validate(keyPath: String, with: NSDictionary) throws {
		for (key, value1) in self {
			let subkey = "\(keyPath).\(key)"
			switch (value1, with[key]) {
			case let (dic1 as NSDictionary, dic2 as NSDictionary):
				try dic1.validate(keyPath: subkey, with: dic2)
			case let (arr1 as NSArray, arr2 as NSArray):
				try arr1.validate(keyPath: subkey, with: arr2)
			case let (obj1 as Double, obj2 as Double) where obj1.distance(to: obj2) < 0.00001:
				break
			case let (obj1 as NSObject, obj2 as NSObject) where obj1.isEqual(obj2):
				break
			default:
				throw DumpError.schemaIsInvalid(subkey)
			}
		}
	}
}

func dump<T: Codable>(_ path: String) throws -> T {
	let data = try Data(contentsOf: URL(fileURLWithPath: root).appendingPathComponent(path))
	let json = try JSONDecoder().decode(T.self, from: data)
	let inverse = try JSONEncoder().encode(json)
	let obj1 = try JSONSerialization.jsonObject(with: data, options: [])
	let obj2 = try JSONSerialization.jsonObject(with: inverse, options: [])
	
	if let dic1 = obj1 as? NSDictionary, let dic2 = obj2 as? NSDictionary {
		try dic1.validate(keyPath: "", with: dic2)
	}
	else if let arr1 = obj1 as? NSArray, let arr2 = obj2 as? NSArray {
		try arr1.validate(keyPath: "", with: arr2)
	}
	
	return json
}

do {
//	let categoryIDs: Schema.CategoryIDs = try dump("/fsd/categoryIDs.yaml")
//	let blueprints: Schema.Blueprints = try dump("/fsd/blueprints.yaml")
//	let certificates: Schema.Certificates = try dump("/fsd/certificates.yaml")
//	let groupIDs: Schema.GroupIDs = try dump("/fsd/groupIDs.yaml")
//	let iconIDs: Schema.IconIDs = try dump("/fsd/iconIDs.yaml")
//	let typeIDs: Schema.TypeIDs = try dump("/fsd/typeIDs.json")
//	let ancestries: Schema.Ancestries = try dump("/bsd/chrAncestries.json")
//	let bloodlines: Schema.Bloodlines = try dump("/bsd/chrBloodlines.json")
//	let factions: Schema.Factions = try dump("/bsd/chrFactions.json")
//	let races: Schema.Races = try dump("/bsd/chrRaces.json")
//	let units: Schema.Units = try dump("/bsd/eveUnits.json")
//	let flags: Schema.Flags = try dump("/bsd/invFlags.json")
//	let items: Schema.Items = try dump("/bsd/invItems.json")
//	let marketGroups: Schema.MarketGroups = try dump("/bsd/invMarketGroups.json")
//	let metaGroups: Schema.MetaGroups = try dump("/bsd/invMetaGroups.json")
//	let metaTypes: Schema.MetaTypes = try dump("/bsd/invMetaTypes.json")
//	let names: Schema.Names = try dump("/bsd/invNames.json")
//	let typeMaterials: Schema.TypeMaterials = try dump("/bsd/invTypeMaterials.json")
//	let typeReactions: Schema.TypeReactions = try dump("/bsd/invTypeReactions.json")
//	let planetSchematics: Schema.PlanetSchematics = try dump("/bsd/planetSchematics.json")
//	let planetSchematicsPinMaps: Schema.PlanetSchematicsPinMaps = try dump("/bsd/planetSchematicsPinMap.json")
//	let planetSchematicsTypeMaps: Schema.PlanetSchematicsTypeMaps = try dump("/bsd/planetSchematicsTypeMap.json")
//	let activities: Schema.Activities = try dump("/bsd/ramActivities.json")
//	let assemblyLineStations: Schema.AssemblyLineStations = try dump("/bsd/ramAssemblyLineStations.json")
//	let assemblyLineTypeDetailPerCategories: Schema.AssemblyLineTypeDetailPerCategories = try dump("/bsd/ramAssemblyLineTypeDetailPerCategory.json")
//	let assemblyLineTypeDetailPerGroups: Schema.AssemblyLineTypeDetailPerGroups = try dump("/bsd/ramAssemblyLineTypeDetailPerGroup.json")
//	let assemblyLineTypes: Schema.AssemblyLineTypes = try dump("/bsd/ramAssemblyLineTypes.json")
//	let installationTypeContents: Schema.InstallationTypeContents = try dump("/bsd/ramInstallationTypeContents.json")
	let stations: Schema.Stations = try dump("/bsd/staStations.json")
	print("Done")
}
catch {
	if case let DumpError.schemaIsInvalid(key) = error {
		print("Invalid: \(key)")
	}
	else {
		print("\(error)")
	}
}



