//
//  NCTextFieldTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit


class NCTextFieldTableViewCell: NCTableViewCell {
	@IBOutlet weak var textField: UITextField!
	@IBOutlet weak var doneButton: UIButton?
	
	var handlers: [UIControlEvents: NCActionHandler<UITextField>] = [:]
	
	override func prepareForReuse() {
		super.prepareForReuse()
		handlers = [:]
	}
}



class NCTextFieldRow: TreeRow {
	var text: String?
	let placeholder: String?
	
	init(prototype: Prototype = Prototype.NCTextFieldTableViewCell.default, text: String? = nil, placeholder: String? = nil) {
		self.text = text
		self.placeholder = placeholder
		super.init(prototype: prototype)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCTextFieldTableViewCell else {return}
		cell.textField.text = text
		let textField = cell.textField
		
		cell.doneButton?.alpha = 0.0
		
		cell.handlers[.editingChanged] = NCActionHandler(cell.textField, for: [.editingChanged], handler: { [weak self] _ in
			self?.text = textField?.text
		})

		cell.handlers[.editingDidBegin] = NCActionHandler(cell.textField, for: [.editingDidBegin], handler: { [weak cell] _ in
			UIView.animate(withDuration: 0.25) {
				cell?.doneButton?.alpha = 1.0
			}
		})

		cell.handlers[.editingDidEnd] = NCActionHandler(cell.textField, for: [.editingDidEnd], handler: { [weak cell] _ in
			UIView.animate(withDuration: 0.25) {
				cell?.doneButton?.alpha = 0.0
			}
		})


		if let placeholder = placeholder {
			cell.textField.attributedPlaceholder = placeholder * [NSAttributedStringKey.foregroundColor: UIColor.lightGray]
		}
	}
	
	//MARK: - Private
	
}

extension Prototype {
	enum NCTextFieldTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCTextFieldTableViewCell", bundle: nil), reuseIdentifier: "NCTextFieldTableViewCell")
	}
}
