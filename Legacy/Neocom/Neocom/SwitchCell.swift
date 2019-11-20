//
//  SwitchCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

typealias SwitchCell = TreeDefaultCell

extension Prototype {
	enum SwitchCell {
		static let `default` = TreeDefaultCell.default
		static let attribute = TreeDefaultCell.attribute
	}
}

extension Tree.Item {
	class SwitchRow: Row<Tree.Content.Default> {
		var handler: (UISwitch) -> Void
		var value: Bool
		
		override func isEqual(_ other: Tree.Item.Base<Tree.Content.Default, TreeItemNull>) -> Bool {
			return super.isEqual(other) && (other as? SwitchRow)?.value == value
		}
		
		init<T: Hashable>(_ content: Tree.Content.Default, value: Bool, diffIdentifier: T, handler: @escaping (UISwitch) -> Void) {
			var content = content
			content.accessoryType = .none
			self.handler = handler
			self.value = value
			super.init(content, diffIdentifier: diffIdentifier)
		}
		
		init(_ content: Tree.Content.Default, value: Bool, handler: @escaping (UISwitch) -> Void) {
			var content = content
			content.accessoryType = .none
			self.handler = handler
			self.value = value
			super.init(content)
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? SwitchCell else {return}
			let switchView = UISwitch(frame: .zero)
			switchView.sizeToFit()
			cell.accessoryView = switchView
			cell.accessoryViewHandler = ActionHandler(switchView, for: .valueChanged) { [weak self] control in
				guard let control = control as? UISwitch else {return}
				let value = control.isOn
				self?.value = value
				self?.handler(control)
			}
		}
	}
}
