//
//  TreeRow.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class TreeRow: TreeNode {
	override var isExpandable: Bool {
		return false
	}
	
	init(cellIdentifier: String) {
		super.init()
		self.cellIdentifier = cellIdentifier
	}
}

class TreeSection: TreeNode {
	override var isExpandable: Bool {
		return true
	}
	
	init(cellIdentifier: String) {
		super.init()
		self.cellIdentifier = cellIdentifier
	}
}
