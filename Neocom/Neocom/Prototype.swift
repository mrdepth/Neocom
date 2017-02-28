//
//  Prototype.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

struct Prototype {
	var nib: UINib?
	var reuseIdentifier: String
}

extension UITableView {
	
	func register(_ prototypes: [Prototype]) {
		for prototype in prototypes {
			register(prototype.nib, forCellReuseIdentifier: prototype.reuseIdentifier)
		}
	}
}
