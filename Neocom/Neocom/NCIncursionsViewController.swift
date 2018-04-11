//
//  NCIncursionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCIncursionsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		tableView.register([Prototype.NCDefaultTableViewCell.noImage])
	}
	
	//MARK: - NCRefreshable
	
	private var incursions: CachedValue<[ESI.Incursions.Incursion]>?
	private var contacts: [Int64: NCContact] = [:]
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		let dataManager = NCDataManager(account: NCAccount.current, cachePolicy: cachePolicy)
		return dataManager.incursions().then(on: .main) { result -> [NCCacheRecord] in
			self.incursions = result
			return [result.cacheRecord]
		}
	}

	override func content() -> Future<TreeNode?> {
		let incursions = self.incursions
		guard let value = incursions?.value else {return .init(.failure(NCTreeViewControllerError.noResult))}
		
		return updateContacts().then(on: .main) { () -> TreeNode? in
			let contacts = self.contacts
			
			let mapSolarSystems = NCDatabase.sharedDatabase?.mapSolarSystems
			
			let rows = value.map { incursion -> NCIncursionRow in
				let row = NCIncursionRow(incursion: incursion, contact: contacts[Int64(incursion.factionID)])
				row.isExpandable = true
				row.isExpanded = false
				row.children = incursion.infestedSolarSystems.compactMap { mapSolarSystems?[$0] }.map { solarSystem -> DefaultTreeRow in
					let location = NCLocation(solarSystem)
					return DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
										  nodeIdentifier: "\(solarSystem.solarSystemID)",
						attributedTitle: location.displayName,
						accessoryType: .disclosureIndicator,
						route: Router.KillReports.ZKillboardReports(filter: [.solarSystemID([Int(solarSystem.solarSystemID)]), .losses]))
				}
				return row
			}
			
			guard !rows.isEmpty else {throw NCTreeViewControllerError.noResult}
			return RootNode(rows)
		}
	}
	
	private func updateContacts() -> Future<Void> {
		var ids = Set(incursions?.value?.map {
			Int64($0.factionID)
		} ?? [])
		
		ids.subtract(contacts.keys)
		if !ids.isEmpty {
			return Progress(totalUnitCount: 1).perform {
				self.dataManager.contacts(ids: ids).then(on: .main) { result -> Void in
					let context = NCCache.sharedCache?.viewContext
					result.forEach {
						self.contacts[$0.key] = (try? context?.existingObject(with: $0.value)) as? NCContact
					}
				}
			}
		}
		else {
			return .init(())
		}
	}
	
}
