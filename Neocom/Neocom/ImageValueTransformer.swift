//
//  ImageValueTransformer.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class ImageValueTransformer: ValueTransformer {
	
	override func transformedValue(_ value: Any?) -> Any? {
		if let image = value as? UIImage {
			return image.pngData()
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
	
	override class func allowsReverseTransformation() -> Bool {
		return true
	}
}
