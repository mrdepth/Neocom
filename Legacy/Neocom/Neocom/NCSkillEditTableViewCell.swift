//
//  NCSkillEditTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 06.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCSkillEditTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var levelSegmentedControl: UISegmentedControl!
	
	var actionHandler: NCActionHandler<UISegmentedControl>?
	
	override func prepareForReuse() {
		super.prepareForReuse()
		actionHandler = nil
	}
	
}


extension Prototype {
	enum NCSkillEditTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCSkillEditTableViewCell")
	}
}

class NCSkillEditRow: NCFetchedResultsObjectNode<NSDictionary>, TreeNodeRoutable {
	var level: Int = 0
	let typeID: Int
	
	var route: Route?
	var accessoryButtonRoute: Route?
	
	required init(object: NSDictionary) {
		typeID = (object["typeID"] as! NSNumber).intValue
		accessoryButtonRoute = Router.Database.TypeInfo(typeID)
		super.init(object: object)
		cellIdentifier = Prototype.NCSkillEditTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCSkillEditTableViewCell else {return}
		cell.titleLabel.text = object["typeName"] as? String
		cell.levelSegmentedControl.selectedSegmentIndex = level
		
		let segmentedControl = cell.levelSegmentedControl!
		cell.actionHandler = NCActionHandler(cell.levelSegmentedControl, for: .valueChanged) { [weak self] _ in
			self?.level = segmentedControl.selectedSegmentIndex
		}
	}
}
