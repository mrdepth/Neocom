//
//  NCLoyaltyPointsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 12.10.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCLoyaltyPointRow: NCContactRow {
	let loyaltyPoints: ESI.Loyalty.Point
	
	init(loyaltyPoints: ESI.Loyalty.Point, contact: NCContact?, dataManager: NCDataManager) {
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
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		dataManager.loyaltyPoints { result in
			self.loyaltyPoints = result
			completionHandler([result.cacheRecord].flatMap {$0})
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = loyaltyPoints?.value {
			tableView.backgroundView = nil
			
			let contactIDs = value.map {Int64($0.corporationID)}
			let dataManager = self.dataManager
			
			dataManager.contacts(ids: Set(contactIDs)) { result in
				let rows = value.map { lp -> NCLoyaltyPointRow in
					return NCLoyaltyPointRow(loyaltyPoints: lp, contact: result[Int64(lp.corporationID)], dataManager: dataManager)
					}.sorted {$0.loyaltyPoints.loyaltyPoints > $1.loyaltyPoints.loyaltyPoints}
				
				self.treeController?.content = RootNode(rows)
				self.tableView.backgroundView = rows.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
				completionHandler()

			}
			
		}
		else {
			tableView.backgroundView = treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: loyaltyPoints?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	//MARK: - NCRefreshable
	
	private var loyaltyPoints: NCCachedResult<[ESI.Loyalty.Point]>?
	
}

