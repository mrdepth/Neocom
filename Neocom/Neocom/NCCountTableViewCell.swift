//
//  NCCountTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 07.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCCountTableViewCell: NCTableViewCell {
	@IBOutlet weak var pickerView: UIPickerView?
	
}

extension Prototype {
	enum NCCountTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCCountTableViewCell")
	}
}

class NCCountRow: TreeRow, UIPickerViewDataSource, UIPickerViewDelegate {
	var value: Int
	var range: Range<Int>
	init(value: Int, range: Range<Int>) {
		self.value = value
		self.range = range
		super.init(prototype: Prototype.NCCountTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCCountTableViewCell else {return}
		cell.pickerView?.dataSource = self
		cell.pickerView?.delegate = self
		cell.pickerView?.reloadAllComponents()
		cell.pickerView?.selectRow(value - range.lowerBound, inComponent: 0, animated: false)
	}
	
	//MARK: - UIPickerViewDataSource
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return range.count
	}
	
	//MARK: - UIPickerViewDelegate
	
	func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
		return String(range.lowerBound + row) * [NSForegroundColorAttributeName: pickerView.tintColor]
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		value = range.lowerBound + row
	}
}
