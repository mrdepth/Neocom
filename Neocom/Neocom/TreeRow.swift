//
//  TreeRow.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

protocol TreeNodeRoutable {
	var route: Route? {get}
	var accessoryButtonRoute: Route? {get}
}

class TreeRow: TreeNode, TreeNodeRoutable {
	var route: Route?
	var accessoryButtonRoute: Route?
	var object: Any?
	override var isExpandable: Bool {
		return false
	}
	
	init(prototype: Prototype, route: Route? = nil, accessoryButtonRoute: Route? = nil, object: Any? = nil) {
		self.route = route
		self.accessoryButtonRoute = accessoryButtonRoute
		self.object = object
		super.init(cellIdentifier: prototype.reuseIdentifier)
	}
	
}

class TreeSection: TreeNode {
	override var isExpandable: Bool {
		return true
	}
	
	init(prototype: Prototype? = nil) {
		super.init(cellIdentifier: prototype?.reuseIdentifier)
	}
}

class DefaultTreeSection: TreeSection {
	let nodeIdentifier: String?
	dynamic var title: String?
	dynamic var attributedTitle: NSAttributedString?

	init(prototype: Prototype = Prototype.NCHeaderTableViewCell.default, nodeIdentifier: String? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, children: [TreeNode]? = nil) {
		self.title = title
		self.attributedTitle = attributedTitle
		self.nodeIdentifier = nodeIdentifier
		super.init(prototype: prototype)
		self.children = children ?? []
	}
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCHeaderTableViewCell {
			cell.object = self
			if title != nil {
				cell.binder.bind("titleLabel.text", toObject: self, withKeyPath: "title", transformer: nil)
			}
			else if attributedTitle != nil {
				cell.binder.bind("titleLabel.attributedText", toObject: self, withKeyPath: "attributedTitle", transformer: nil)
			}
		}
	}
	
	override func transitionStyle(from node: TreeNode) -> TransitionStyle {
		guard let node = node as? DefaultTreeSection else {return .none}
		
		if let title = self.title {
			return title != node.title ? .reload : .none
		}
		else if let attributedTitle = self.attributedTitle {
			return attributedTitle != self.attributedTitle ? .reload : .none
		}
		else {
			return .none
		}
	}
	
	override var hashValue: Int {
		return nodeIdentifier?.hashValue ?? super.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		guard let nodeIdentifier = nodeIdentifier else {return super.isEqual(object)}
		return nodeIdentifier.hashValue == (object as? DefaultTreeSection)?.nodeIdentifier?.hashValue
	}
}

class DefaultTreeRow: TreeRow {
	dynamic var image: UIImage?
	dynamic var title: String?
	dynamic var attributedTitle: NSAttributedString?
	dynamic var subtitle: String?
	dynamic var accessoryType: UITableViewCellAccessoryType
	
	init(prototype: Prototype = Prototype.NCDefaultTableViewCell.default, image: UIImage? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, subtitle: String? = nil, accessoryType: UITableViewCellAccessoryType = .none, route: Route? = nil, accessoryButtonRoute: Route? = nil, object: Any? = nil) {
		self.image = image
		self.title = title
		self.attributedTitle = attributedTitle
		self.subtitle = subtitle
		self.accessoryType = accessoryType

		super.init(prototype: prototype, route: route, accessoryButtonRoute: accessoryButtonRoute, object: object)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.object = object
		cell.iconView?.image = image
		if let attributedTitle = attributedTitle {
			cell.titleLabel?.attributedText = attributedTitle
		}
		else {
			cell.titleLabel?.text = title
		}
		cell.subtitleLabel?.text = subtitle
		cell.accessoryType = accessoryType
	}
}

class NCActionRow: TreeRow {
	
	var title: String?
	var attributedTitle: NSAttributedString?
	
	init(prototype: Prototype = Prototype.NCActionTableViewCell.default, title: String? = nil, attributedTitle: NSAttributedString? = nil, route: Route? = nil, object: Any? = nil) {
		self.title = title
		self.attributedTitle = attributedTitle
		super.init(prototype: prototype, route: route, object: object)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCActionTableViewCell else {return}
		cell.object = object
		if let attributedTitle = attributedTitle {
			cell.titleLabel?.attributedText = attributedTitle
		}
		else {
			cell.titleLabel?.text = title
		}
	}
	
	override var hashValue: Int {
		return [route?.hashValue ?? 0, title?.hashValue ?? 0].hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCActionRow)?.hashValue == hashValue
	}
	
}



class NCDefaultFetchedResultsSectionNode<ResultType: NSFetchRequestResult>: FetchedResultsSectionNode<ResultType> {
	
	required init(section: NSFetchedResultsSectionInfo, objectNode: FetchedResultsObjectNode<ResultType>.Type) {
		super.init(section: section, objectNode: objectNode)
		self.cellIdentifier = Prototype.NCHeaderTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.titleLabel?.text = section.name.uppercased()
	}
	
	override var isExpandable: Bool {
		return true
	}
}

class NCMetaGroupFetchedResultsSectionNode<ResultType: NSFetchRequestResult>: FetchedResultsSectionNode<ResultType> {
	let metaGroupID: Int?
	lazy var metaGroup: NCDBInvMetaGroup? = {
		guard let metaGroupID = self.metaGroupID else {return nil}
		return NCDatabase.sharedDatabase?.invMetaGroups[metaGroupID]
	}()
	
	required init(section: NSFetchedResultsSectionInfo, objectNode: FetchedResultsObjectNode<ResultType>.Type) {
		metaGroupID = Int(section.name)
		super.init(section: section, objectNode: objectNode)
		self.cellIdentifier = Prototype.NCHeaderTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.titleLabel?.text = metaGroup?.metaGroupName?.uppercased()
	}
	
	override var isExpandable: Bool {
		return true
	}
}

class NCTypeInfoNode: FetchedResultsObjectNode<NCDBInvType> {
	var segue: String?
	var accessoryButtonSegue: String?
	
	required init(object: NCDBInvType) {
		super.init(object: object)
		self.cellIdentifier = Prototype.NCDefaultTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCDefaultTableViewCell {
			cell.titleLabel?.text = object.typeName
			cell.iconView?.image = object.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.object = object
		}
	}
}

class NCTypeInfoRow: TreeRow {
	let managedObjectContext: NSManagedObjectContext?
	let accessoryType: UITableViewCellAccessoryType
	lazy var type: NCDBInvType? = {
		if let objectID = self.object as? NSManagedObjectID {
			return (try? self.managedObjectContext?.existingObject(with: objectID)) as? NCDBInvType
		}
		else {
			return (self.object as? NCDBInvType)
		}
	}()

	init(type: NCDBInvType, accessoryType: UITableViewCellAccessoryType = .none, route: Route? = nil, accessoryButtonRoute: Route? = nil) {
		self.managedObjectContext = nil
		self.accessoryType = accessoryType
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact, route: route, accessoryButtonRoute: accessoryButtonRoute, object: type)
	}
	
	init(objectID: NSManagedObjectID, managedObjectContext: NSManagedObjectContext, accessoryType: UITableViewCellAccessoryType = .none, route: Route? = nil, accessoryButtonRoute: Route? = nil) {
		self.managedObjectContext = managedObjectContext
		self.accessoryType = accessoryType
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact, route: route, accessoryButtonRoute: accessoryButtonRoute, object: objectID)
	}
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCDefaultTableViewCell {
			cell.titleLabel?.text = type?.typeName
			cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.object = type
			cell.accessoryType = accessoryType
		}
	}

	override var hashValue: Int {
		return type?.hash ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCTypeInfoRow)?.hashValue == hashValue
	}

}
