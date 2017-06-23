//
//  NCKillmailTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCKillmailTableViewCell: NCTableViewCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var bossImageView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var stateLabel: UILabel!
	@IBOutlet weak var progressLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		let layer = self.progressView.superview?.layer;
		layer?.borderColor = UIColor(number: 0x3d5866ff).cgColor
		layer?.borderWidth = 1.0 / UIScreen.main.scale
	}
}

extension Prototype {
	enum NCKillmailTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCKillmailTableViewCell")
	}
}

class NCKillmailRow: TreeRow {
	
	let killmail: ESI.Killmails.Killmail
	let dataManager: NCDataManager
	
	init(killmail: ESI.Killmails.Killmail, dataManager: NCDataManager) {
		self.killmail = killmail
		self.dataManager = dataManager
		super.init(prototype: Prototype.NCKillmailTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		
		guard let cell = cell as? NCIncursionTableViewCell else {return}
	}
	
	override var hashValue: Int {
		return killmail.killmailID
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCKillmailRow)?.hashValue == hashValue
	}
}
