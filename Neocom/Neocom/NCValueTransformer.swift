//
//  NCValueTransformer.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

public class NCValueTransformer: ValueTransformer {
	let handler: (Any?) -> Any?
	
	public init(handler: @escaping (Any?) -> Any?) {
		self.handler = handler
	}
	
	public override func transformedValue(_ value: Any?) -> Any? {
		return handler(value)
	}
}
