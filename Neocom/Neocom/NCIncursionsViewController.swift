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
	
	private var incursions: NCCachedResult<[ESI.Incursions.Incursion]>?
	private var contacts: [Int64: NCContact] = [:]
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		let progress = Progress(totalUnitCount: 1)
		
		let dataManager = NCDataManager(account: NCAccount.current, cachePolicy: cachePolicy)
		
		progress.perform {
			dataManager.incursions { result in
				self.incursions = result
				completionHandler([result.cacheRecord].flatMap {$0})
			}
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = incursions?.value {
			updateContacts {
				let contacts = self.contacts
				
				let mapSolarSystems = NCDatabase.sharedDatabase?.mapSolarSystems
				
				let rows = value.map { incursion -> NCIncursionRow in
					let row = NCIncursionRow(incursion: incursion, contact: contacts[Int64(incursion.factionID)])
					row.isExpandable = true
					row.isExpanded = false
					row.children = incursion.infestedSolarSystems.flatMap { mapSolarSystems?[$0] }.map { solarSystem -> DefaultTreeRow in
						let location = NCLocation(solarSystem)
						return DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
						                      nodeIdentifier: "\(solarSystem.solarSystemID)",
							attributedTitle: location.displayName,
							accessoryType: .disclosureIndicator,
							route: Router.KillReports.ZKillboardReports(filter: [.solarSystemID([Int(solarSystem.solarSystemID)]), .losses]))
					}
					return row
				}
				
				
				if self.treeController?.content == nil {
					let root = TreeNode()
					root.children = rows
					self.treeController?.content = root
				}
				else {
					self.treeController?.content?.children = rows
				}
				self.tableView.backgroundView = rows.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
				completionHandler()
			}
		}
		else {
			tableView.backgroundView = treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: incursions?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private func updateContacts(completionHandler: @escaping () -> Void) {
		var ids = Set(incursions?.value?.map {
			Int64($0.factionID)
		} ?? [])
		
		ids.formSymmetricDifference(Set(contacts.keys))
		if !ids.isEmpty {
			Progress(totalUnitCount: 1).perform {
				self.dataManager.contacts(ids: ids) { result in
					result.forEach {
						self.contacts[$0.key] = $0.value
					}
					completionHandler()
				}
			}
		}
		else {
			completionHandler()
		}
	}
	
}
