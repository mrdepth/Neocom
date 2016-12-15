//
//  NCTableViewAccountCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCTableViewAccountCell: NCTableViewCell {
	@IBOutlet weak var characterNameLabel: UILabel!
	@IBOutlet weak var characterImageView: UIImageView!
	@IBOutlet weak var corporationLabel: UILabel!
	@IBOutlet weak var spLabel: UILabel!
	@IBOutlet weak var wealthLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var subscriptionLabel: UILabel!
	@IBOutlet weak var skillLabel: UILabel!
	@IBOutlet weak var trainingTimeLabel: UILabel!
	@IBOutlet weak var skillQueueLabel: UILabel!
	@IBOutlet weak var trainingProgressView: UIProgressView!
	
	var progressHandler: NCProgressHandler?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		let layer = self.trainingProgressView.superview?.layer;
		layer?.borderColor = UIColor(number: 0x3d5866ff).cgColor
		layer?.borderWidth = 1.0 / UIScreen.main.scale
	}
}
