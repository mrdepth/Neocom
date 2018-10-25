//
//  TreeHeaderCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class TreeHeaderCell: HeaderCell {
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

class TreeHeaderEditingActionCell: TreeHeaderCell {
	
	override func awakeFromNib() {
		super.awakeFromNib()
		editingAccessoryView = UIButton(type: .custom)
		(editingAccessoryView as? UIButton)?.setImage(#imageLiteral(resourceName: "actionsItem.pdf"), for: .normal)
		editingAccessoryView?.sizeToFit()
	}
}

extension Prototype {
	enum TreeHeaderCell {
		static let `default` = Prototype(nib: UINib(nibName: "TreeHeaderCell", bundle: nil), reuseIdentifier: "TreeHeaderCell")
//		static let editingAction = Prototype(nib: UINib(nibName: "TreeHeaderEditingActionCell", bundle: nil), reuseIdentifier: "TreeHeaderEditingActionCell")
	}
}

extension Tree.Content {
	struct Section: Hashable {
		var prototype: Prototype?
		var title: String?
		var attributedTitle: NSAttributedString?
		var isExpanded: Bool
		
		init (prototype: Prototype = Prototype.TreeHeaderCell.default, title: String? = nil, attributedTitle: NSAttributedString? = nil, isExpanded: Bool = true) {
			self.prototype = prototype
			self.title = title
			self.attributedTitle = attributedTitle
			self.isExpanded = isExpanded
		}
	}
}

extension Tree.Item {
	
	class Section<Element: TreeItem>: Collection<Tree.Content.Section, Element>, ExpandableItem {
		
		var action: ((UIControl) -> Void)?
		var editingAction: ((UIControl) -> Void)?

		weak var treeController: TreeController?
		var isExpanded: Bool {
			get {
				return content.isExpanded
			}
			set {
				content.isExpanded = newValue
				if let cell = treeController?.cell(for: self) {
					configure(cell: cell, treeController: treeController)
				}
				treeController?.deselectCell(for: self, animated: true)
			}
		}
		
		var expandIdentifier: CustomStringConvertible?
		
		init<T: Hashable>(_ content: Tree.Content.Section, diffIdentifier: T, expandIdentifier: CustomStringConvertible? = nil, treeController: TreeController?, children: [Element]? = nil, action: ((UIControl) -> Void)? = nil, editingAction: ((UIControl) -> Void)? = nil) {
			self.action = action
			self.editingAction = editingAction
			self.treeController = treeController
			self.expandIdentifier = expandIdentifier
			self.action = action
			self.editingAction = editingAction

			super.init(content, diffIdentifier: diffIdentifier, children: children)
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			configureActions(for: cell, treeController: treeController)
			guard let cell = cell as? TreeHeaderCell else {return}
			
			cell.expandIconView?.image = treeController?.isItemExpanded(self) == true ? #imageLiteral(resourceName: "collapse") : #imageLiteral(resourceName: "expand")
		}
		
		func configureActions(for cell: UITableViewCell, treeController: TreeController?) {
			guard let cell = cell as? TreeHeaderCell else {return}
			
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
	
	class SimpleSection<Element: TreeItem>: Section<Element> {
		init(title: String, treeController: TreeController?, children: [Element]? = nil) {
			let identifier = "\(type(of: self)).\(title)"
			super.init(Tree.Content.Section(title: title), diffIdentifier: identifier, expandIdentifier: identifier, treeController: treeController, children: children)
		}
	}
}

extension Tree.Content.Section: CellConfiguring {
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeHeaderCell else {return}
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


