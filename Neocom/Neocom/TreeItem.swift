//
//  TreeItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

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


extension UICollectionView {
	
	func register(_ prototypes: [Prototype]) {
		for prototype in prototypes {
			register(prototype.nib, forCellWithReuseIdentifier: prototype.reuseIdentifier)
		}
	}
}


protocol SelfConfiguringItem {
	var cellIdentifier: String? {get}
	func configure(cell: UITableViewCell) -> Void
}

protocol ExpandableItem {
	var initiallyExpanded: Bool {get}
	var expandIdentifier: CustomStringConvertible? {get}
}

extension ExpandableItem {
	var initiallyExpanded: Bool {
		return true
	}
	
	var expandIdentifier: CustomStringConvertible? {
		return nil
	}
}
