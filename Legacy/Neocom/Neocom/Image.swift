//
//  Image.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/28/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

struct Image: Hashable {
	var value: UIImage
	var identifier: AnyHashable
	
	var hashValue: Int {
		return identifier.hashValue
	}
	
	static func == (lhs: Image, rhs: Image) -> Bool {
		return lhs.identifier == rhs.identifier
	}
	
	init?(_ icon: SDEEveIcon?) {
		guard let icon = icon else {return nil}
		guard let image = icon.image?.image else {return nil}
		self.value = image
		identifier = icon.objectID
	}
	
	init(_ image: UIImage) {
		value = image
		identifier = image
	}
}
