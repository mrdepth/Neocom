//
//  String+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

extension String {
	private static let numbers = ["0","I","II","III","IV","V"]
	
	init(romanNumber: Int) {
		self = String.numbers[romanNumber.clamped(to: 0...5)]
//		self.init(String.numbers[romanNumber.clamped(to: 0...5)])!
	}
}
