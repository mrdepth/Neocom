//
//  NCLoyaltyStoreOffersViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 12.10.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCLoyaltyStoreCategoryRow: TreeRow {
	let categoryID: Int
	
	lazy var category: NCDBInvCategory? = {
		return NCDatabase.sharedDatabase?.invCategories[categoryID]
	}()
	
	init(categoryID: Int, route: Route) {
		self.categoryID = categoryID
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact, route: route)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = category?.categoryName
		cell.iconView?.image = category?.icon?.image?.image ?? NCDBEveIcon.defaultCategory.image?.image
		cell.accessoryType = .disclosureIndicator
	}
}

class NCLoyaltyStoreGroupRow: TreeRow {
	let groupID: Int
	
	lazy var group: NCDBInvGroup? = {
		return NCDatabase.sharedDatabase?.invGroups[groupID]
	}()
	
	init(groupID: Int, route: Route) {
		self.groupID = groupID
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact, route: route)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = group?.groupName
		cell.iconView?.image = group?.icon?.image?.image ?? NCDBEveIcon.defaultGroup.image?.image
		cell.accessoryType = .disclosureIndicator
	}
}

class NCLoyaltyStoreOfferRow: TreeRow {
	let offer: ESI.Loyalty.Offer

	lazy var subtitle: String = {
		var components = [String]()
		if offer.lpCost > 0 {
			components.append(NCUnitFormatter.localizedString(from: offer.lpCost, unit: .custom(NSLocalizedString("LP", comment: ""), false), style: .full))
		}
		if offer.iskCost > 0 {
			components.append(NCUnitFormatter.localizedString(from: offer.lpCost, unit: .isk, style: .full))
		}
		if !offer.requiredItems.isEmpty {
//			offer.requiredItems.flat
			components.append(String(format: NSLocalizedString("%d items", comment: ""), offer.requiredItems.count))
		}
		return components.joined(separator: ", ")
	}()
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.offer.typeID]
	}()
	
	init(offer: ESI.Loyalty.Offer) {
		self.offer = offer
		super.init(prototype: Prototype.NCDefaultTableViewCell.default, route: Router.Database.TypeInfo(offer.typeID))
		
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.subtitleLabel?.text = subtitle
		cell.accessoryType = .disclosureIndicator
	}
}

class NCLoyaltyStoreOffersViewController: NCTreeViewController {
	
	var loyaltyPoints: ESI.Loyalty.Point?
	
	enum Filter {
		case category(Int)
		case group(Int)
	}
	
	var filter: Filter?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCHeaderTableViewCell.default])
		
		let label = NCNavigationItemTitleLabel(frame: CGRect(origin: .zero, size: .zero))
		
		let title: String = {
			switch filter {
			case let .category(categoryID)?:
				return NCDatabase.sharedDatabase?.invCategories[categoryID]?.categoryName
			case let .group(groupID)?:
				return NCDatabase.sharedDatabase?.invGroups[groupID]?.groupName
			default:
				return nil
			}
		}() ?? NSLocalizedString("Offers", comment: "")
		
		
		label.set(title: title, subtitle: NCUnitFormatter.localizedString(from: loyaltyPoints?.loyaltyPoints ?? 0, unit: .custom("LP", false), style: .full))
		navigationItem.titleView = label

	}
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		guard let loyaltyPoints = loyaltyPoints, filter == nil && offers == nil else {
			return .init([])
		}
		
		return dataManager.loyaltyStoreOffers(corporationID: Int64(loyaltyPoints.corporationID)).then(on: .main) { result -> [NCCacheRecord] in
			self.offers = result
			return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
		}
	}
	
	override func content() -> Future<TreeNode?> {
		let loyaltyPoints = self.loyaltyPoints
		let offers = self.offers

		return DispatchQueue.global(qos: .utility).async { () -> TreeNode? in
			guard let loyaltyPoints = loyaltyPoints, let offers = offers, let value = offers.value else {throw NCTreeViewControllerError.noResult}
			return try NCDatabase.sharedDatabase!.performTaskAndWait { (managedObjectContext) in
				let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
				//				var map: [Int: [NCLoyaltyStoreOfferRow]] = [:]
				
				let sections: [TreeNode]
				
				switch self.filter {
				case let .category(categoryID)?:
					let categoryID = Int32(categoryID)
					let groups = Set(value.compactMap {invTypes[$0.typeID]?.group}).filter {$0.category?.categoryID == categoryID}
					sections = groups.sorted {($0.groupName ?? "") < ($1.groupName ?? "")}.map {NCLoyaltyStoreGroupRow(groupID: Int($0.groupID), route: Router.Character.LoyaltyStoreOffers(loyaltyPoints: loyaltyPoints, filter: .group(Int($0.groupID)), offers: offers))}
				case let .group(groupID)?:
					let groupID = Int32(groupID)
					
					let types = value.compactMap { i -> (NCDBInvType, ESI.Loyalty.Offer)? in
						guard let type = invTypes[i.typeID], type.group?.groupID == groupID else {return nil}
						return (type, i)
					}
					sections = types.sorted {($0.0.typeName ?? "") < ($1.0.typeName ?? "")}.map {NCLoyaltyStoreOfferRow(offer: $0.1)}
					
				default:
					let categories = Set(value.compactMap {invTypes[$0.typeID]?.group?.category})
					sections = categories.sorted {($0.categoryName ?? "") < ($1.categoryName ?? "")}.map {NCLoyaltyStoreCategoryRow(categoryID: Int($0.categoryID), route: Router.Character.LoyaltyStoreOffers(loyaltyPoints: loyaltyPoints, filter: .category(Int($0.categoryID)), offers: offers))}
				}
				
				guard !sections.isEmpty else {throw NCTreeViewControllerError.noResult}
				return RootNode(sections)
			}
		}
	}
	
	//MARK: - NCRefreshable
	
	var offers: CachedValue<[ESI.Loyalty.Offer]>?
	
}


