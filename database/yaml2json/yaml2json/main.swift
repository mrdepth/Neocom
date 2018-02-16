//
//  main.swift
//  yaml2json
//
//  Created by Artem Shimanski on 15.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

enum YAMLDecoderError: Error {
	case formatError
	case invalidArgument
}

extension yaml_parser_t: IteratorProtocol {
	public mutating func next() -> YAMLDecoder.Token? {
		var event = yaml_event_t()
		guard yaml_parser_parse(&self, &event) != 0 else {return nil}
		defer {yaml_event_delete(&event)}
		return YAMLDecoder.Token(event: event)
	}
}

public class YAMLDecoder {
	public enum Token {
		case streamStart
		case streamEnd
		case documentStart
		case documentEnd
		case alias
		case scalar (String, Bool)
		case sequenceStart
		case sequenceEnd
		case mappingStart
		case mappingEnd
		init?(event: yaml_event_t) {
			switch event.type {
			case YAML_STREAM_START_EVENT:
				self = .streamStart
			case YAML_STREAM_END_EVENT:
				self = .streamEnd
			case YAML_DOCUMENT_START_EVENT:
				self = .documentStart
			case YAML_DOCUMENT_END_EVENT:
				self = .documentEnd
			case YAML_ALIAS_EVENT:
				self = .alias
			case YAML_SCALAR_EVENT:
				guard let value = event.data.scalar.value else {return nil}
				guard let scalar = String(bytesNoCopy: value, length: event.data.scalar.length, encoding: .utf8, freeWhenDone: false) else {return nil}
				self = .scalar(scalar, event.data.scalar.quoted_implicit != 0)
			case YAML_SEQUENCE_START_EVENT:
				self = .sequenceStart
			case YAML_SEQUENCE_END_EVENT:
				self = .sequenceEnd
			case YAML_MAPPING_START_EVENT:
				self = .mappingStart
			case YAML_MAPPING_END_EVENT:
				self = .mappingEnd
			default:
				return nil
			}
		}
		
		var value: Any? {
			switch self {
			case let .scalar(value, quotedImplicit):
				return quotedImplicit ? value : Int(value) ?? Double(value) ?? Bool(value) ?? value
			default:
				return nil
			}
		}
	}
	
	private enum Kind {
		case value
		case sequence
		case mapping
		
		func decode(_ parser: inout yaml_parser_t) throws -> Any {
			
			switch self {
			case .value:
				repeat {
					guard let token = parser.next() else {throw YAMLDecoderError.formatError}
					switch token {
					case .scalar:
						return token.value!
					case .sequenceStart:
						return try Kind.sequence.decode(&parser)
					case .mappingStart:
						return try Kind.mapping.decode(&parser)
					case .sequenceEnd, .mappingEnd:
						throw YAMLDecoderError.formatError
					default:
						break
					}
				}
					while (true)
				
				
			case .sequence:
				var values = [Any]()
				repeat {
					guard let token = parser.next() else {throw YAMLDecoderError.formatError}
					switch token {
					case .scalar:
						values.append(token.value!)
					case .sequenceStart:
						values.append(try Kind.sequence.decode(&parser))
					case .mappingStart:
						values.append(try Kind.mapping.decode(&parser))
					case .sequenceEnd:
						return values
					case .mappingEnd:
						throw YAMLDecoderError.formatError
					default:
						break
					}
				}
					while (true)
				
			case .mapping:
				var values = [String: Any]()
				repeat {
					guard let token = parser.next() else {throw YAMLDecoderError.formatError}
					switch token {
					case let .scalar(key, _):
						try values[key] = Kind.value.decode(&parser)
					case .sequenceStart, .mappingStart, .sequenceEnd:
						throw YAMLDecoderError.formatError
					case .mappingEnd:
						return values
					default:
						break
					}
				}
					while (true)
			}
		}
	}
	
	private var parser: yaml_parser_t
	init() {
		parser = .init()
		yaml_parser_initialize(&parser)
	}
	
	func decode(from data: Data) throws -> Data {
		return try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) throws -> Data in
			yaml_parser_set_input_string(&parser, bytes, data.count)
			
			let value = try Kind.value.decode(&parser)
			return try JSONSerialization.data(withJSONObject: value, options: [])
		}
	}
	
	deinit {
		yaml_parser_delete(&parser)
	}
}

do {
	guard CommandLine.arguments.count > 1 else {throw YAMLDecoderError.invalidArgument}
	let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1], relativeTo: nil))
	let output = try YAMLDecoder().decode(from: data)
	guard let s = String(data: output, encoding: .utf8) else {throw YAMLDecoderError.invalidArgument}
	print(s)
	exit(0)
}
catch {
	print("Error: \(error)")
	exit(1)
}


