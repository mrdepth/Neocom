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

}

class NCActionHandler {
	private let handler: NCOpaqueHandler
	private let control: UIControl
	private let controlEvents: UIControlEvents
	
	class NCOpaqueHandler: NSObject {
		let handler: (UIControl) -> Void
		
		init(_ handler: @escaping(UIControl) -> Void) {
			self.handler = handler
		}
		
		func handle(_ sender: UIControl) {
			handler(sender)
		}

	}
	
	init(_ control: UIControl, for controlEvents: UIControlEvents, handler: @escaping(UIControl) -> Void) {
		self.handler = NCOpaqueHandler(handler)
		self.control = control
		self.controlEvents = controlEvents
		control.addTarget(self.handler, action: #selector(NCOpaqueHandler.handle(_:)), for: controlEvents)
	}
	
	deinit {
		control.removeTarget(self.handler, action: #selector(NCOpaqueHandler.handle(_:)), for: controlEvents)
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
	
	private var handler: NCActionHandler?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCTextFieldTableViewCell else {return}
		cell.textField.text = text
		let textField = cell.textField
		handler = NCActionHandler(cell.textField, for: .editingChanged, handler: { [weak self] _ in
			self?.text = textField?.text
		})
		
		if let placeholder = placeholder {
			cell.textField.attributedPlaceholder = placeholder * [NSForegroundColorAttributeName: UIColor.lightGray]
		}
	}
	
	//MARK: - Private
	
}

extension Prototype {
	enum NCTextFieldTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCTextFieldTableViewCell", bundle: nil), reuseIdentifier: "NCTextFieldTableViewCell")
	}
}
