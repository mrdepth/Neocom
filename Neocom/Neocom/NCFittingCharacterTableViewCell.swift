//
//  NCFittingCharacterTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

extension UIImage {
	class func placeholder(text: String, size: CGSize) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
		let context = UIGraphicsGetCurrentContext()

		let rect = CGRect(origin: .zero, size: size)

		context?.fill(rect)
		
		context?.setBlendMode(.clear)
		

		let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
		paragraph.alignment = .center
		let font = UIFont.boldSystemFont(ofSize: round(size.height * 0.7))
		let attributes = [NSAttributedStringKey.font:font, NSAttributedStringKey.paragraphStyle: paragraph]
		let s = text * attributes
		let c = NSStringDrawingContext()
		c.minimumScaleFactor = 0.5
		s.draw(with: rect.insetBy(dx: 0, dy: (size.height - font.lineHeight) / 2), options: [.usesLineFragmentOrigin], context: nil)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysTemplate)
		UIGraphicsEndImageContext()
		return image!
	}
}

class NCFittingCharacterTableViewCell: NCTableViewCell {
	@IBOutlet weak var characterNameLabel: UILabel!
	@IBOutlet weak var characterImageView: UIImageView!
}

extension Prototype {
	enum NCFittingCharacterTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCFittingCharacterTableViewCell", bundle: nil), reuseIdentifier: "NCFittingCharacterTableViewCell")
	}
}

class NCPredefinedCharacterRow: TreeRow {
	let level: Int
	let url: URL?

	init(level: Int, route: Route? = nil) {
		self.level = level
		url = NCFittingCharacter.url(level: level)
		super.init(prototype: Prototype.NCFittingCharacterTableViewCell.default, route: route)
	}
	
	private var image: UIImage?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingCharacterTableViewCell else {return}
		
		cell.characterImageView?.image = image
		
		let s = NCPredefinedCharacterRow.titles[level]
		cell.characterNameLabel.text = NSLocalizedString("All Skills", comment: "") + " " + s
		if image == nil {
			image = UIImage.placeholder(text: s, size: cell.characterImageView.bounds.size)
			cell.characterImageView.image = image
		}
		cell.object = level
	}
	
	override var hashValue: Int {
		return level.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCPredefinedCharacterRow)?.hashValue == hashValue
	}
	
	private static var titles = ["0", "I", "II", "III", "IV", "V"]

}

class NCCustomCharactersSection: FetchedResultsNode<NCFitCharacter> {
	
	init(managedObjectContext: NSManagedObjectContext) {
		let request = NSFetchRequest<NCFitCharacter>(entityName: "FitCharacter")
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		try? controller.performFetch()
		super.init(resultsController: controller, objectNode: NCCustomCharacterRow.self)
		cellIdentifier = Prototype.NCHeaderTableViewCell.default.reuseIdentifier
		isExpandable = true
	}
	
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCHeaderTableViewCell {
			cell.object = self
			cell.titleLabel?.text = NSLocalizedString("Custom", comment: "").uppercased()
		}
	}
	
	override func loadChildren() {
		super.loadChildren()
		children.append(NCActionRow(title: NSLocalizedString("Add Character", comment: "").uppercased()))
	}
	
	override var hashValue: Int {
		return #line
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCCustomCharactersSection)?.hashValue == hashValue
	}
}

class NCCustomCharacterRow: NCFetchedResultsObjectNode<NCFitCharacter>, TreeNodeRoutable {
	var route: Route?
	var accessoryButtonRoute: Route?
	let url: URL?

	convenience init(character: NCFitCharacter, route: Route? = nil) {
		self.init(object: character)
		self.route = route
	}
	
	required init(object: NCFitCharacter) {
		url = NCFittingCharacter.url(character: object)
		super.init(object: object)
		self.cellIdentifier = Prototype.NCFittingCharacterTableViewCell.default.reuseIdentifier
	}
	
	var image: UIImage?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingCharacterTableViewCell else {return}
		cell.object = object
		cell.characterImageView.image = image
		cell.characterNameLabel.text = object.name ?? NSLocalizedString("Unnamed", comment: "")
		if image == nil {
			let s: String
			if let name = object.name, !name.isEmpty {
				s = name.substring(to: name.index(after: name.startIndex))
			}
			else {
				s = "C"
			}
			image = UIImage.placeholder(text: s, size: cell.characterImageView.bounds.size)
		}
		cell.characterImageView.image = image
	}
}

class NCAccountCharactersSection: FetchedResultsNode<NCAccount> {
	
	init(managedObjectContext: NSManagedObjectContext) {
		let request = NSFetchRequest<NCAccount>(entityName: "Account")
		request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		try? controller.performFetch()
		super.init(resultsController: controller, objectNode: NCAccountCharacterRow.self)
		cellIdentifier = Prototype.NCHeaderTableViewCell.default.reuseIdentifier
		isExpandable = true
	}
	
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCHeaderTableViewCell {
			cell.object = self
			cell.titleLabel?.text = NSLocalizedString("Accounts", comment: "").uppercased()
		}
	}
	
	override var hashValue: Int {
		return #line
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCAccountCharactersSection)?.hashValue == hashValue
	}
}


class NCAccountCharacterRow: NCFetchedResultsObjectNode<NCAccount>, TreeNodeRoutable {
	var route: Route?
	var accessoryButtonRoute: Route?
	let url: URL?
	
	convenience init(account: NCAccount, route: Route? = nil) {
		self.init(object: account)
		self.route = route
	}

	required init(object: NCAccount) {
		url = NCFittingCharacter.url(account: object)
		super.init(object: object)
		self.cellIdentifier = Prototype.NCFittingCharacterTableViewCell.default.reuseIdentifier
	}
	
	var image: UIImage?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingCharacterTableViewCell else {return}
		cell.characterNameLabel.text = object.characterName
		cell.object = object
		if image == nil {
			NCDataManager(account: object).image(characterID: object.characterID, dimension: Int(cell.characterImageView.bounds.size.width)) { result in
				if (cell.object as? NCAccount) === self.object {
					switch result {
					case let .success(value, _):
						self.image = value
						if (cell.object as? NCAccount) == self.object {
							cell.characterImageView.image = value
						}
					default:
						break
					}
				}
			}
		}
	}
}
