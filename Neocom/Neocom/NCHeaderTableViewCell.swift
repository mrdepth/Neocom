//
//  NCHeaderTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCHeaderTableViewCell: UITableViewCell, NCExpandable, Expandable {

	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var expandIconView: UIImageView?
	var object: Any?
	private(set) lazy var binder: NCBinder = {
		return NCBinder(target: self)
	}()

    override func awakeFromNib() {
        super.awakeFromNib()
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		tintColor = .caption
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
		expandIconView?.image = expanded ? #imageLiteral(resourceName: "collapse") : #imageLiteral(resourceName: "expand")
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

class NCActionHeaderTableViewCell: NCHeaderTableViewCell {
	@IBOutlet weak var button: UIButton?
}

extension Prototype {
	enum NCHeaderTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCHeaderTableViewCell")
		static let action = Prototype(nib: UINib(nibName: "NCActionHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCActionHeaderTableViewCell")
	}
	enum NCActionHeaderTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCActionHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCActionHeaderTableViewCell")
	}
}

class NCActionTreeSection: DefaultTreeSection {
	
	override init(prototype: Prototype = Prototype.NCActionHeaderTableViewCell.default, nodeIdentifier: String? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, children: [TreeNode]? = nil) {
		super.init(prototype: prototype, nodeIdentifier: nodeIdentifier, title: title, attributedTitle: attributedTitle, children: children)
	}
	
	var handler: NCActionHandler?
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCActionHeaderTableViewCell else {return}
		handler = NCActionHandler(cell.button!, for: .touchUpInside) { [weak self] _ in
			guard let strongSelf = self else {return}
			guard let controller = strongSelf.treeController else {return}
			controller.delegate?.treeController?(controller, accessoryButtonTappedWithNode: strongSelf)
		}
	}
}

class NCSkillsHeaderTableViewCell: NCHeaderTableViewCell {
	var trainingQueue: NCTrainingQueue?
	var character: NCCharacter?
	@IBOutlet weak var trainButton: UIButton?

}
