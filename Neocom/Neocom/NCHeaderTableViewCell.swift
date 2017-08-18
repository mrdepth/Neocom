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
		tintColor = .caption
		indentationWidth = 16
		selectionStyle = .none
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
			guard let stackView = self.titleLabel?.superview else {return nil}
			return stackView.superview?.constraints.first {
				return $0.firstItem === stackView && $0.secondItem === stackView.superview && $0.firstAttribute == .leading && $0.secondAttribute == .leading
			}
		}
	}
	
	override var indentationWidth: CGFloat {
		didSet {
			updateIndent()
		}
	}
	
	override var indentationLevel: Int {
		didSet {
			updateIndent()
		}
	}
	
	private func updateIndent() {
		let level = max(0, indentationLevel)
		let indent = 8 + CGFloat(level) * indentationWidth
		self.indentationConstraint?.constant = indent
		self.separatorInset.left = indent
	}
}

class NCActionHeaderTableViewCell: NCHeaderTableViewCell {
	@IBOutlet weak var button: UIButton?
	
	var handler: NCActionHandler?
}

extension Prototype {
	enum NCHeaderTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCHeaderTableViewCell")
		static let action = Prototype(nib: UINib(nibName: "NCActionHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCActionHeaderTableViewCell")
		static let image = Prototype(nib: UINib(nibName: "NCImageHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCImageHeaderTableViewCell")
		static let empty = Prototype(nib: UINib(nibName: "NCEmptyHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCEmptyHeaderTableViewCell")
	}
	enum NCActionHeaderTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCActionHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCActionHeaderTableViewCell")
	}
}

class NCActionTreeSection: DefaultTreeSection {
	
	override init(prototype: Prototype = Prototype.NCActionHeaderTableViewCell.default, nodeIdentifier: String? = nil, image: UIImage? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, children: [TreeNode]? = nil) {
		super.init(prototype: prototype, nodeIdentifier: nodeIdentifier, image: image, title: title, attributedTitle: attributedTitle, children: children)
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
