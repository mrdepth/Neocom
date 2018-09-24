//
//  DgmAttributeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class DgmAttributeCell: TreeDefaultCell {
	
}

extension Prototype {
	enum DgmAttributeCell {
		static let `default` = Prototype(nib: UINib(nibName: "DgmAttributeCell", bundle: nil), reuseIdentifier: "DgmAttributeCell")
	}
}
