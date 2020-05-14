//
//  NCLoyaltyPointsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 12.10.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData
import Futures

class NCLoyaltyPointRow: NCContactRow {
	let loyaltyPoints: ESI.Loyalty.Point
	
	init(loyaltyPoints: ESI.Loyalty.Point, contact: NSManagedObjectID?, dataManager: NCDataManager) {
		self.loyaltyPoints = loyaltyPoints
		super.init(prototype: Prototype.NCContactTableViewCell.default, contact: contact, dataManager: dataManager, route: Router.Character.LoyaltyStoreOffers(loyaltyPoints: loyaltyPoints))
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCContactTableViewCell else {return}
		cell.subtitleLabel?.text = NCUnitFormatter.localizedString(from: loyaltyPoints.loyaltyPoints, unit: .custom(NSLocalizedString("points", comment: ""), false), style: .full)
		cell.accessoryType = .disclosureIndicator
	}
}

class NCLoyaltyPointsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		tableView.register([Prototype.NCContactTableViewCell.default])
	}
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		return dataManager.loyaltyPoints().then(on: .main) { result -> [NCCacheRecord] in
			self.loyaltyPoints = result
			return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
		}
	}
	
	override func content() -> Future<TreeNode?> {
		return DispatchQueue.global(qos: .utility).async { () -> TreeNode? in
			guard let value = self.loyaltyPoints?.value else {throw NCTreeViewControllerError.noResult}
			let contactIDs = value.map {Int64($0.corporationID)}
			let dataManager = self.dataManager
			
			let rows = try dataManager.contacts(ids: Set(contactIDs)).then { result -> [NCLoyaltyPointRow] in
				let rows = value.map { lp -> NCLoyaltyPointRow in
					return NCLoyaltyPointRow(loyaltyPoints: lp, contact: result[Int64(lp.corporationID)], dataManager: dataManager)
					}.sorted {$0.loyaltyPoints.loyaltyPoints > $1.loyaltyPoints.loyaltyPoints}
				return rows
			}.get()
			guard !rows.isEmpty else {throw NCTreeViewControllerError.noResult}
			return RootNode(rows)
		}
	}
	
	//MARK: - NCRefreshable
	
	private var loyaltyPoints: CachedValue<[ESI.Loyalty.Point]>?
}

