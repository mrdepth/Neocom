//
//  NCShipTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCShipTableViewCell: NCTableViewCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var hiSlotsLabel: UILabel!
	@IBOutlet weak var medSlotsLabel: UILabel!
	@IBOutlet weak var lowSlotsLabel: UILabel!
	@IBOutlet weak var rigSlotsLabel: UILabel!
	@IBOutlet weak var turretsLabel: UILabel!
	@IBOutlet weak var launchersLabel: UILabel!
}

extension Prototype {
	enum NCShipTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCShipTableViewCell", bundle: nil), reuseIdentifier: "NCShipTableViewCell")
	}
}
