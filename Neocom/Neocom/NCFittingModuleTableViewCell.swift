//
//  NCFittingModuleTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingModuleTableViewCell: NCTableViewCell {
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var stateView: UIImageView?
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var subtitleLabel: UILabel?
	@IBOutlet weak var targetIconView: UIImageView!
}

class NCFittingModuleStateTableViewCell: NCTableViewCell {
	@IBOutlet weak var segmentedControl: UISegmentedControl?
}

typealias NCFittingDroneTableViewCell = NCFittingModuleTableViewCell
typealias NCFittingDroneStateTableViewCell = NCFittingModuleStateTableViewCell
typealias NCFittingBoosterTableViewCell = NCFittingModuleStateTableViewCell

extension Prototype {
	enum NCFittingModuleTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCFittingModuleTableViewCell", bundle: nil), reuseIdentifier: "NCFittingModuleTableViewCell")
	}
	
	enum NCFittingModuleStateTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCFittingModuleStateTableViewCell", bundle: nil), reuseIdentifier: "NCFittingModuleStateTableViewCell")
	}
	

	typealias NCFittingDroneTableViewCell = Prototype.NCFittingModuleTableViewCell
	typealias NCFittingDroneStateTableViewCell = Prototype.NCFittingModuleStateTableViewCell
	typealias NCFittingBoosterTableViewCell = Prototype.NCFittingModuleStateTableViewCell

}
