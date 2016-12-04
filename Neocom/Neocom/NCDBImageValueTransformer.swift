//
//  NCDBImageValueTransformer.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCDBImageValueTransformer: ValueTransformer {
	
	override class func initialize() {
		if self == NCDBImageValueTransformer.self {
			ValueTransformer.setValueTransformer(NCDBImageValueTransformer(), forName: NSValueTransformerName("NCDBImageValueTransformer"))
		}
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		if let image = value as? UIImage {
			return UIImagePNGRepresentation(image)
		}
		else {
			return nil
		}
	}
	
	override func reverseTransformedValue(_ value: Any?) -> Any? {
		if let data = value as? Data {
			return UIImage(data: data)
		}
		else {
			return nil
		}
	}
}
