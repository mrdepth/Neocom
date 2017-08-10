//
//  NCImageFromDataValueTransformer.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

class NCImageFromDataValueTransformer: ValueTransformer {
	override func transformedValue(_ value: Any?) -> Any? {
		guard let data = value as? Data else {return nil}
		return UIImage(data: data, scale: UIScreen.main.scale)
	}
}
