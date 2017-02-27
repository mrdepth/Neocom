//
//  NCHeaderTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCHeaderTableViewCell: UITableViewCell, NCExpandable, Expandable {
	struct prototypes {
		static let `default` = TableViewCellPrototype(nib: UINib(nibName: "NCHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCHeaderTableViewCell")
	}

	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var expandIconView: UIImageView?
	var object: Any?
	private(set) lazy var binder: NCBinder = {
		return NCBinder(target: self)
	}()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

	override func prepareForReuse() {
		binder.unbindAll()
		super.prepareForReuse()
	}

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
	func setExpanded(_ expanded: Bool, animated: Bool) {
		expandIconView?.image = UIImage(named: expanded ? "collapse" : "expand")
	}
	
	var indentationConstraint: NSLayoutConstraint? {
		get {
			guard let expandIconView = self.expandIconView else {return nil}
			return expandIconView.superview?.constraints.first {
				return $0.firstItem === expandIconView && $0.secondItem === expandIconView.superview && $0.firstAttribute == .leading && $0.secondAttribute == .leading
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
