//
//  main.swift
//  sde-tool
//
//  Created by Artem Shimanski on 13.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation




let root = CommandLine.arguments[1]

@discardableResult
func exec(_ args: String...) -> (Int32, Data) {
	let pipe = Pipe()
	let task = Process()
	task.launchPath = "/usr/bin/env"
	task.arguments = args
	task.standardOutput = pipe
	var data = Data()
	pipe.fileHandleForReading.readabilityHandler = { handle in
		data.append(handle.readDataToEndOfFile())
	}
	task.launch()
	task.waitUntilExit()
	return (task.terminationStatus, data)
}

extension Data {
	init?(yamlPath: String) {
		let python = "import sys, yaml, json; file = open(sys.argv[1], 'r'); y=yaml.load(file.read()); print json.dumps(y, ensure_ascii=False, separators=(',', ':'), encoding='utf-8').encode('utf-8')"
		let result = exec("python", "-c", python, yamlPath)
		guard result.0 == 0 else {return nil}
		self = result.1
	}
}

enum DumpError: Error {
	case fileNotFound
	case schemaIsInvalid
}

func dump<T: Codable>(_ path: String) throws -> T {
	guard let data = Data(yamlPath: root + path) else {throw DumpError.fileNotFound}
	let json = try JSONDecoder().decode(T.self, from: data)
	let inverse = try JSONEncoder().encode(json)
	let dic1 = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
	let dic2 = try JSONSerialization.jsonObject(with: inverse, options: []) as! NSDictionary
	guard dic1 == dic2 else {throw DumpError.schemaIsInvalid}
	return json
}

do {
//	let categoryIDs: Schema.CategoryIDs = try dump("/fsd/categoryIDs.yaml")
//	let blueprints: Schema.Blueprints = try dump("/fsd/blueprints.yaml")
//	let certificates: Schema.Certificates = try dump("/fsd/certificates.yaml")
//	let groupIDs: Schema.GroupIDs = try dump("/fsd/groupIDs.yaml")
//	let iconIDs: Schema.IconIDs = try dump("/fsd/iconIDs.yaml")
	let typeIDs: Schema.TypeIDs = try dump("/fsd/typeIDs.yaml")
	print("Done")
}
catch {
	print("\(error)")
}



