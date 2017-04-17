//
//  NCMailTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCMailTableViewCell: NCTableViewCell {
	@IBOutlet weak var recipientLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var subjectLabel: UILabel!
	@IBOutlet weak var iconView: UIImageView!
	
}

extension Prototype {
	enum NCMailTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCMailTableViewCell")
	}
}

class NCMailFetchedResultsNode: FetchedResultsNode<NCMail> {
	let account: NCAccount
	
	init?(account: NCAccount) {
		guard let context = NCCache.sharedCache?.viewContext else {return nil}
		self.account = account
		let request = NSFetchRequest<NCMail>(entityName: "Mail")
		request.predicate = NSPredicate(format: "characterID == %qi", account.characterID)
		request.sortDescriptors = [NSSortDescriptor(key: "folder", ascending: true), NSSortDescriptor(key: "timestamp", ascending: false)]
		
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "folder", cacheName: nil)
		
		super.init(resultsController: controller, sectionNode: NCMailSection.self, objectNode: NCMailRow.self)
	}
}

class NCMailSection: FetchedResultsSectionNode<NCMail> {
	
	required init(section: NSFetchedResultsSectionInfo, objectNode: FetchedResultsObjectNode<NCMail>.Type) {
		super.init(section: section, objectNode: objectNode)
		cellIdentifier = Prototype.NCHeaderTableViewCell.default.reuseIdentifier
		isExpanded = false
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		guard let i = Int(section.name) else {return}
		guard let folder = NCMail.Folder(rawValue: i) else {return}
		cell.titleLabel?.text = folder.name
	}
}

class NCMailRow: FetchedResultsObjectNode<NCMail> {
	
	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .short
		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter
	}()
	
	required init(object: NCMail) {
		super.init(object: object)
		cellIdentifier = Prototype.NCMailTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCMailTableViewCell else {return}
		cell.subjectLabel.text = object.subject
		if let date = object.timestamp as Date? {
			cell.dateLabel.text = NCMailRow.dateFormatter.string(from: date)
		}
		else {
			cell.dateLabel.text = nil
		}
	}
}
