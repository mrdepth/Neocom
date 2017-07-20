//
//  NCModuleTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCModuleTableViewCell: NCTableViewCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var powerGridLabel: UILabel!
	@IBOutlet weak var cpuLabel: UILabel!
}

extension Prototype {
	enum NCModuleTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCModuleTableViewCell", bundle: nil), reuseIdentifier: "NCModuleTableViewCell")
	}
}
