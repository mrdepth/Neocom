//
//  Error.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

enum NCError: Error {
	case invalidArgument(type: Any?, function: String, argument: String, value: Any?)
	case noCachedResult(type: Any, identifier: String)
	case missingCharacterID(function: String)
	case cancelled(type: Any?, function: String)
}
