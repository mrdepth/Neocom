//
//  TreeSectionCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class TreeSectionCell: HeaderCell {
	@IBOutlet var titleLabel: UILabel?
	@IBOutlet var expandIconView: UIImageView?

	var action: ActionHandler<UIButton>?
	var button: UIButton? {
		get {
			return accessoryView as? UIButton
		}
		set {
			accessoryView = newValue
		}
	}

	var editingAction: ActionHandler<UIButton>?
	var editingButton: UIButton? {
		get {
			return editingAccessoryView as? UIButton
		}
		set {
			editingAccessoryView = newValue
		}
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		action = nil
		editingAction = nil
	}
}

extension Prototype {
	enum TreeSectionCell {
		static let `default` = Prototype(nib: UINib(nibName: "TreeSectionCell", bundle: nil), reuseIdentifier: "TreeSectionCell")
	}
}

extension Tree.Content {
	struct Section: Hashable {
		var prototype: Prototype?
		var title: String?
		var attributedTitle: NSAttributedString?
//		var isExpanded: Bool
		
		init (prototype: Prototype = Prototype.TreeSectionCell.default, title: String? = nil, attributedTitle: NSAttributedString? = nil/*, isExpanded: Bool = true*/) {
			self.prototype = prototype
			self.title = title
			self.attributedTitle = attributedTitle
//			self.isExpanded = isExpanded
		}
	}
}

extension Tree.Item {
	
	class Section<Content: Hashable, Element: TreeItem>: Collection<Content, Element>, ItemExpandable {
		
		var action: ((UIControl) -> Void)?
		var editingAction: ((UIControl) -> Void)?

		weak var treeController: TreeController?
		var isExpanded: Bool
		
		var expandIdentifier: CustomStringConvertible?
		
		init<T: Hashable>(_ content: Content, isExpanded: Bool = true, diffIdentifier: T, expandIdentifier: CustomStringConvertible? = nil, treeController: TreeController?, children: [Element]? = nil, action: ((UIControl) -> Void)? = nil, editingAction: ((UIControl) -> Void)? = nil) {
			self.action = action
			self.editingAction = editingAction
			self.treeController = treeController
			self.expandIdentifier = expandIdentifier
			self.action = action
			self.editingAction = editingAction
			self.isExpanded = isExpanded

			super.init(content, diffIdentifier: diffIdentifier, children: children)
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			configureActions(for: cell, treeController: treeController)
			guard let cell = cell as? TreeSectionCell else {return}
			
//			cell.expandIconView?.image = treeController?.isItemExpanded(self) == true ? #imageLiteral(resourceName: "collapse") : #imageLiteral(resourceName: "expand")
			cell.expandIconView?.image = isExpanded ? #imageLiteral(resourceName: "collapse") : #imageLiteral(resourceName: "expand")
		}
		
		func configureActions(for cell: UITableViewCell, treeController: TreeController?) {
			guard let cell = cell as? TreeSectionCell else {return}
			
			if let handler = action {
				cell.button = UIButton(type: .custom)
				cell.button?.setImage(#imageLiteral(resourceName: "actionsItem.pdf"), for: .normal)
				cell.button?.sizeToFit()
				cell.action = ActionHandler(cell.button!, for: .touchUpInside, handler: handler)
			}
			else {
				cell.button = nil
			}
			
			if let handler = editingAction {
				cell.editingButton = UIButton(type: .custom)
				cell.editingButton?.setImage(#imageLiteral(resourceName: "actionsItem.pdf"), for: .normal)
				cell.editingButton?.sizeToFit()
				cell.editingAction = ActionHandler(cell.editingButton!, for: .touchUpInside, handler: handler)
			}
			else {
				cell.editingButton = nil
			}
		}
	}
	
	class SimpleSection<Element: TreeItem>: Section<Tree.Content.Section, Element> {
		init(title: String, treeController: TreeController?, children: [Element]? = nil) {
			let identifier = "\(type(of: self)).\(title)"
			super.init(Tree.Content.Section(title: title), diffIdentifier: identifier, expandIdentifier: identifier, treeController: treeController, children: children)
		}
	}
}

extension Tree.Content.Section: CellConfigurable {
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeSectionCell else {return}
		if let attributedTitle = attributedTitle {
			cell.titleLabel?.attributedText = attributedTitle
			cell.titleLabel?.isHidden = false
		}
		else if let title = title {
			cell.titleLabel?.text = title
			cell.titleLabel?.isHidden = false
		}
		else {
			cell.titleLabel?.text = nil
			cell.titleLabel?.isHidden = true
		}
	}
}
