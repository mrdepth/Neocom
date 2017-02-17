//
//  NCDamagePatternEditTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 16.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCDamagePatternEditTableViewCell: NCTextFieldTableViewCell {
	@IBOutlet weak var pickerView: UIPickerView?
}

class NCDamagePatternEditRow: TreeRow, UIPickerViewDataSource, UIPickerViewDelegate {
	var damagePattern: NCDamagePattern
	init(damagePattern: NCDamagePattern) {
		self.damagePattern = damagePattern
		super.init(cellIdentifier: "NCDamagePatternEditTableViewCell")
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDamagePatternEditTableViewCell else {return}
		cell.pickerView?.delegate = self
		cell.pickerView?.dataSource = self
		cell.pickerView?.reloadAllComponents()
		cell.pickerView?.selectRow(Int(round(damagePattern.em * 100)), inComponent: 0, animated: false)
		cell.pickerView?.selectRow(Int(round(damagePattern.thermal * 100)), inComponent: 1, animated: false)
		cell.pickerView?.selectRow(Int(round(damagePattern.kinetic * 100)), inComponent: 2, animated: false)
		cell.pickerView?.selectRow(Int(round(damagePattern.explosive * 100)), inComponent: 3, animated: false)
		
	}
	
	override var hashValue: Int {
		return damagePattern.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCDamagePatternEditRow)?.hashValue == hashValue
	}
	
	override func move(from: TreeNode) -> TreeNodeReloading {
		return .reconfigure
	}
	
	//MARK: - UIPickerViewDataSource
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 4
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		
		return 101
	}
	
	//MARK: - UIPickerViewDelegate
	
	static let damages = [NCDamageType.em, NCDamageType.thermal, NCDamageType.kinetic, NCDamageType.explosive]
	
//	func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
//		return "\(row)%" * [NSForegroundColorAttributeName: NCDamagePatternEditRow.colors[component], NSFontAttributeName: UIFont.preferredFont(forTextStyle: .subheadline)]
//	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		let value = Float(row) / 100.0
		switch NCDamagePatternEditRow.damages[component] {
		case .em:
			damagePattern.em = value
		case .thermal:
			damagePattern.thermal = value
		case .kinetic:
			damagePattern.kinetic = value
		case .explosive:
			damagePattern.explosive = value
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
		let label = (view as? UILabel) ?? UILabel()
		let font = UIFont.preferredFont(forTextStyle: .headline)
		let damage = NCDamagePatternEditRow.damages[component]
		label.attributedText = NSAttributedString(image: damage.image, font: font) + "\(row)%" * [NSForegroundColorAttributeName: damage.color, NSFontAttributeName: font]
		label.textAlignment = .center
		return label
	}
	
}
