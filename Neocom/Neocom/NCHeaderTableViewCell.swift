//
//  NCHeaderTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCHeaderTableViewCell: UITableViewCell, NCExpandable {
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var expandIcon: UIImageView?
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
	func setExpanded(_ expanded: Bool, animated: Bool) {
		expandIcon?.image = UIImage(named: expanded ? "collapse" : "expand")
	}
	
	var indentationConstraint: NSLayoutConstraint? {
		get {
			guard let expandIcon = self.expandIcon else {return nil}
			return expandIcon.superview?.constraints.first {
				return $0.firstItem === expandIcon && $0.secondItem === expandIcon.superview && $0.firstAttribute == .leading && $0.secondAttribute == .leading
			}
		}
	}
	
	override var indentationLevel: Int {
		didSet {
			//let level = max(0, indentationLevel - 1)
			self.indentationConstraint?.constant = CGFloat(8 + indentationLevel * 10)
		}
	}

}

class NCSkillsHeaderTableViewCell: NCHeaderTableViewCell {
	var trainingQueue: NCTrainingQueue?
	var character: NCCharacter?
	@IBOutlet weak var trainButton: UIButton?

}
