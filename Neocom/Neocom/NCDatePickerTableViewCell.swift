//
//  NCDatePickerTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCDatePickerTableViewCell: NCTableViewCell {
	@IBOutlet weak var datePicker: UIDatePicker!
	
	var actionHandler: NCActionHandler?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		datePicker.setValue(UIColor.white, forKeyPath: "textColor")
		datePicker.setValue(false, forKeyPath: "highlightsToday")
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		actionHandler = nil
	}
}

extension Prototype {
	enum NCDatePickerTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCDatePickerTableViewCell", bundle: nil), reuseIdentifier: "NCDatePickerTableViewCell")
	}
}

class NCDatePickerRow: TreeRow {
	var value: Date
	var range: Range<Date>
	var handler: ((Date) -> Void)?
	
	init(value: Date, range:Range<Date>, handler: ((Date) -> Void)?) {
		self.value = value
		self.range = range
		self.handler = handler
		super.init(prototype: Prototype.NCDatePickerTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDatePickerTableViewCell else {return}
		cell.datePicker.minimumDate = range.lowerBound
		cell.datePicker.maximumDate = range.upperBound
		cell.datePicker.date = value
		cell.actionHandler = NCActionHandler(cell.datePicker, for: .valueChanged) { [weak self] control in
			guard let strongSelf = self else {return}
			let picker = control as! UIDatePicker
			strongSelf.value = picker.date
			strongSelf.handler?(picker.date)
		}
	}
	
}

