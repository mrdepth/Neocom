//
//  ImageValueTransformer.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation

class ImageValueTransformer: NSSecureUnarchiveFromDataTransformer {
	override class var allowedTopLevelClasses: [AnyClass] {
		return [UIImage.self]
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		if let data = value as? Data {
			return UIImage(data: data)
		}
		else {
			return nil
		}
	}
	
	override func reverseTransformedValue(_ value: Any?) -> Any? {
		if let image = value as? UIImage {
			return image.pngData()
		}
		else {
			return nil
		}
	}
	
	override class func allowsReverseTransformation() -> Bool {
		return true
	}
}
