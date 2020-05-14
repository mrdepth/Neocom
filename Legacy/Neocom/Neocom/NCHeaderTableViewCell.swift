//
//  NCHeaderTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCHeaderTableViewCell: UITableViewCell, Expandable {

	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var expandIconView: UIImageView?
	var object: Any?

    override func awakeFromNib() {
        super.awakeFromNib()
		tintColor = .caption
		indentationWidth = 16
		selectionStyle = .none
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

typealias NCFooterTableViewCell = NCHeaderTableViewCell

class NCActionHeaderTableViewCell: NCHeaderTableViewCell {
	@IBOutlet weak var button: UIButton?
	
	var actionHandler: NCActionHandler<UIButton>?
	
	override func prepareForReuse() {
		super.prepareForReuse()
		actionHandler = nil
	}
}

extension Prototype {
	enum NCHeaderTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCHeaderTableViewCell")
		static let action = Prototype(nib: UINib(nibName: "NCActionHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCActionHeaderTableViewCell")
		static let image = Prototype(nib: UINib(nibName: "NCImageHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCImageHeaderTableViewCell")
		static let empty = Prototype(nib: UINib(nibName: "NCEmptyHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCEmptyHeaderTableViewCell")
		static let `static` = Prototype(nib: UINib(nibName: "NCStaticHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCStaticHeaderTableViewCell")
	}
	enum NCActionHeaderTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCActionHeaderTableViewCell", bundle: nil), reuseIdentifier: "NCActionHeaderTableViewCell")
	}
	enum NCFooterTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCFooterTableViewCell", bundle: nil), reuseIdentifier: "NCFooterTableViewCell")
	}
}

class NCActionTreeSection: DefaultTreeSection {
	
	override init(prototype: Prototype = Prototype.NCActionHeaderTableViewCell.default, nodeIdentifier: String? = nil, image: UIImage? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, isExpandable: Bool = true, children: [TreeNode]? = nil) {
		super.init(prototype: prototype, nodeIdentifier: nodeIdentifier, image: image, title: title, attributedTitle: attributedTitle, isExpandable: isExpandable, children: children)
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCActionHeaderTableViewCell else {return}
		cell.actionHandler = NCActionHandler(cell.button!, for: .touchUpInside) { [weak self] _ in
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

class NCFooterRow: TreeRow {
	var title: String?
	var attributedTitle: NSAttributedString?
	let nodeIdentifier: String?
	
	init(prototype: Prototype = Prototype.NCFooterTableViewCell.default, nodeIdentifier: String? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, route: Route? = nil, object: Any? = nil) {
		self.title = title
		self.attributedTitle = attributedTitle
		self.nodeIdentifier = nodeIdentifier
		super.init(prototype: prototype, route: route, accessoryButtonRoute: nil, object: object)
	}
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCFooterTableViewCell {
			cell.object = self
			if title != nil {
				cell.titleLabel?.text = title
			}
			else if attributedTitle != nil {
				cell.titleLabel?.attributedText = attributedTitle
			}
		}
	}
	
	override var hash: Int {
		return nodeIdentifier?.hashValue ?? super.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		guard let nodeIdentifier = nodeIdentifier else {return super.isEqual(object)}
		return nodeIdentifier.hashValue == (object as? NCFooterRow)?.nodeIdentifier?.hashValue
	}

}
