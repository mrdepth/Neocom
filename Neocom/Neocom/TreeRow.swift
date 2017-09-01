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

public enum NCTableViewCellAccessoryType {
    
    
    case none
    case disclosureIndicator
    case detailDisclosureButton
    case checkmark
    case detailButton
    case button(UIImage)
}

protocol CollapseSerializable {
	var collapseState: NCCacheSectionCollapse? {get}
}

class RootNode: TreeNode, CollapseSerializable {
	let collapseState: NCCacheSectionCollapse?
	
	init(_ children: [TreeNode] = [], collapseIdentifier: String? = nil) {
		if let collapseIdentifier = collapseIdentifier {
			collapseState = NCCache.sharedCache?.viewContext.fetch("SectionCollapse", where: "identifier == %@", collapseIdentifier) ?? {
				let state = NCCacheSectionCollapse(entity: NSEntityDescription.entity(forEntityName: "SectionCollapse!", in: NCCache.sharedCache!.viewContext)!, insertInto: NCCache.sharedCache!.viewContext)
				state.identifier = collapseIdentifier
				state.isExpanded = true
				return state
			}()
		}
		else {
			collapseState = nil
		}
		super.init()
		self.children = children
	}
}

class TreeRow: TreeNode, TreeNodeRoutable {
	var route: Route?
	var accessoryButtonRoute: Route?
	var object: Any?
	
	init(prototype: Prototype, route: Route? = nil, accessoryButtonRoute: Route? = nil, object: Any? = nil) {
		self.route = route
		self.accessoryButtonRoute = accessoryButtonRoute
		self.object = object
		super.init(cellIdentifier: prototype.reuseIdentifier)
		isExpandable = false
	}
	
	override var separatorInset: UIEdgeInsets {
		if isLeaf && (children.isEmpty || !isExpanded) {
			return sequence(first: self, next: {$0.parent}).first {!$0.isLeaf}?.separatorInset ?? .zero
		}
		else {
			return UIEdgeInsets(top: 0, left: CGFloat(15 + indentationLevel * 8), bottom: 0, right: 0)
		}
	}
	
}

class TreeSection: TreeNode {
	init(prototype: Prototype? = nil) {
		super.init(cellIdentifier: prototype?.reuseIdentifier)
		isExpandable = true
	}
	
	override var separatorInset: UIEdgeInsets {
		return isLeaf && (children.isEmpty || !isExpanded) ? sequence(first: self, next: {$0.parent}).first {!$0.isLeaf}?.separatorInset ?? .zero : parent?.separatorInset ?? .zero
	}
}

class DefaultTreeSection: TreeSection {
	let nodeIdentifier: String?
	let image: UIImage?
	var title: String?
	var attributedTitle: NSAttributedString?

	init(prototype: Prototype = Prototype.NCHeaderTableViewCell.default, nodeIdentifier: String? = nil, image: UIImage? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, children: [TreeNode]? = nil) {
		self.image = image
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
				cell.titleLabel?.text = title
//				cell.binder.bind("titleLabel.text", toObject: self, withKeyPath: "title", transformer: nil)
			}
			else if attributedTitle != nil {
				cell.titleLabel?.attributedText = attributedTitle
//				cell.binder.bind("titleLabel.attributedText", toObject: self, withKeyPath: "attributedTitle", transformer: nil)
			}
			cell.iconView?.image = image
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
	var image: UIImage?
	var title: String?
	var attributedTitle: NSAttributedString?
	var subtitle: String?
	var attributedSubtitle: NSAttributedString?
	var accessoryType: NCTableViewCellAccessoryType
	let nodeIdentifier: String?
	
	init(prototype: Prototype = Prototype.NCDefaultTableViewCell.default, nodeIdentifier: String? = nil, image: UIImage? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, subtitle: String? = nil, attributedSubtitle: NSAttributedString? = nil, accessoryType: NCTableViewCellAccessoryType = .none, route: Route? = nil, accessoryButtonRoute: Route? = nil, object: Any? = nil) {
		self.nodeIdentifier = nodeIdentifier
		self.image = image
		self.title = title
		self.attributedTitle = attributedTitle
		self.subtitle = subtitle
		self.attributedSubtitle = attributedSubtitle
		self.accessoryType = accessoryType

		super.init(prototype: prototype, route: route, accessoryButtonRoute: accessoryButtonRoute, object: object)
	}
	
    private var buttonHandler: NCActionHandler?
	
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
		if let attributedSubtitle = attributedSubtitle {
			cell.subtitleLabel?.attributedText = attributedSubtitle
		}
		else {
			cell.subtitleLabel?.text = subtitle
		}
        cell.accessoryView = nil
        switch accessoryType {
        case .checkmark:
            cell.accessoryType = .checkmark
        case .detailButton:
            cell.accessoryType = .detailButton
        case .detailDisclosureButton:
            cell.accessoryType = .detailDisclosureButton
        case .disclosureIndicator:
            cell.accessoryType = .disclosureIndicator
        case .none:
            cell.accessoryType = .none
        case let .button(image):
            let button = UIButton(type: .system)
            button.setImage(image, for: .normal)
            button.sizeToFit()
            buttonHandler = NCActionHandler(button, for: .touchUpInside) { [weak self] _ in
                guard let strongSelf = self else {return}
                guard let treeController = strongSelf.treeController else {return}
                treeController.delegate?.treeController?(treeController, accessoryButtonTappedWithNode: strongSelf)
            }
            cell.accessoryView = button
        }
		cell.backgroundColor = .cellBackground
	}
	
	override var hashValue: Int {
		return nodeIdentifier?.hash ?? super.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? DefaultTreeRow)?.hashValue == hashValue
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
		let h = route != nil ? Unmanaged.passUnretained(route!).toOpaque().hashValue : 0
		return [h, title?.hashValue ?? 0].hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCActionRow)?.hashValue == hashValue
	}	
}



class NCDefaultFetchedResultsSectionNode<ResultType: NSFetchRequestResult>: FetchedResultsSectionNode<ResultType> {
	
	required init(section: NSFetchedResultsSectionInfo, objectNode: FetchedResultsObjectNode<ResultType>.Type) {
		super.init(section: section, objectNode: objectNode)
		self.cellIdentifier = Prototype.NCHeaderTableViewCell.default.reuseIdentifier
		isExpandable = true
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.titleLabel?.text = section.name.uppercased()
	}
	
}

class NCDefaultFetchedResultsSectionCollapsedNode<ResultType: NSFetchRequestResult>: NCDefaultFetchedResultsSectionNode<ResultType> {
	required init(section: NSFetchedResultsSectionInfo, objectNode: FetchedResultsObjectNode<ResultType>.Type) {
		super.init(section: section, objectNode: objectNode)
		self.cellIdentifier = Prototype.NCHeaderTableViewCell.default.reuseIdentifier
		isExpandable = true
		isExpanded = false
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
		isExpandable = true
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.titleLabel?.text = metaGroup?.metaGroupName?.uppercased()
	}
	
}


class NCTypeInfoRow: TreeRow {
	let managedObjectContext: NSManagedObjectContext?
	let accessoryType: UITableViewCellAccessoryType
	
	lazy var type: NCDBInvType? = {
		if let objectID = self.object as? NSManagedObjectID {
			return (try? (self.managedObjectContext ?? NCDatabase.sharedDatabase?.viewContext)?.existingObject(with: objectID)) as? NCDBInvType
		}
		else if let typeID = self.object as? Int {
			guard let context = self.managedObjectContext ?? NCDatabase.sharedDatabase?.viewContext else {return nil}
			return NCDBInvType.invTypes(managedObjectContext: context)[typeID]
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
	
	init(objectID: NSManagedObjectID, managedObjectContext: NSManagedObjectContext? = nil, accessoryType: UITableViewCellAccessoryType = .none, route: Route? = nil, accessoryButtonRoute: Route? = nil) {
		self.managedObjectContext = managedObjectContext
		self.accessoryType = accessoryType
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact, route: route, accessoryButtonRoute: accessoryButtonRoute, object: objectID)
	}

	init(typeID: Int, managedObjectContext: NSManagedObjectContext? = nil, accessoryType: UITableViewCellAccessoryType = .none, route: Route? = nil, accessoryButtonRoute: Route? = nil) {
		self.managedObjectContext = managedObjectContext
		self.accessoryType = accessoryType
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact, route: route, accessoryButtonRoute: accessoryButtonRoute, object: typeID)
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

class NCFetchedResultsObjectNode<ResultType: NSFetchRequestResult>: FetchedResultsObjectNode<ResultType> {
	
	override var separatorInset: UIEdgeInsets {
		if isLeaf && (children.isEmpty || !isExpanded) {
			return sequence(first: self, next: {$0.parent}).first {!$0.isLeaf}?.separatorInset ?? .zero
		}
		else {
			return UIEdgeInsets(top: 0, left: CGFloat(15 + indentationLevel * 8), bottom: 0, right: 0)
		}
	}
}
