//
//  NCEventTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCEventTableViewCell: NCTableViewCell {
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var stateLabel: UILabel!
	
}

extension Prototype {
	enum NCEventTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCEventTableViewCell")
	}
}

class NCEventRow: TreeRow {
	let event: ESI.Calendar.Summary
	
	init(event: ESI.Calendar.Summary) {
		self.event = event
		super.init(prototype: Prototype.NCEventTableViewCell.default, route: Router.Calendar.Event(event: event))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCEventTableViewCell else {return}
		cell.titleLabel.text = event.title
		if let date = event.eventDate {
			cell.dateLabel.text = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
		}
		else {
			cell.dateLabel.text = nil
		}
		cell.stateLabel.text = (event.eventResponse ?? .notResponded).title
		
	}
	
	override lazy var hashValue: Int = event.hashValue
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCEventRow)?.hashValue == hashValue
	}
	
}
