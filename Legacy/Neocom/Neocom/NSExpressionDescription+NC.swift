//
//  NSExpressionDescription+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import CoreData

extension NSExpressionDescription {
	convenience init(name: String, resultType: NSAttributeType, expression: NSExpression) {
		self.init()
		self.name = name
		self.expressionResultType = resultType
		self.expression = expression
	}
}
