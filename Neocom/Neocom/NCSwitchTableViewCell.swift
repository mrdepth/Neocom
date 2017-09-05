//
//  NCSwitchTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCSwitchTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var switchControl: UISwitch!
	
	var actionHandler: NCActionHandler?
	
	override func prepareForReuse() {
		super.prepareForReuse()
		actionHandler = nil
	}

}

extension Prototype {
	enum NCSwitchTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCSwitchTableViewCell", bundle: nil), reuseIdentifier: "NCSwitchTableViewCell")
	}
}

class NCSwitchRow: TreeRow {
	var handler: ((Bool) -> Void)?
	let title: String
	var value: Bool
	
	init(title: String, value: Bool, handler: ((Bool) -> Void)?) {
		self.title = title
		self.value = value
		self.handler = handler
		super.init(prototype: Prototype.NCSwitchTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCSwitchTableViewCell else {return}
		cell.titleLabel.text = title
		cell.switchControl.isOn = value
		
		cell.actionHandler = NCActionHandler(cell.switchControl, for: .valueChanged) { [weak self] control in
			guard let strongSelf = self else {return}
			let picker = control as! UISwitch
			strongSelf.value = picker.isOn
			strongSelf.handler?(picker.isOn)
		}
	}
}
