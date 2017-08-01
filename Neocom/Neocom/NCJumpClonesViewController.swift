//
//  NCJumpClonesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCJumpClonesViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		needsReloadOnAccountChange = true
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.attribute,
		                    Prototype.NCDefaultTableViewCell.placeholder])
	}

	private var clones: NCCachedResult<EVE.Char.Clones>?
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		
		dataManager.clones { result in
			self.clones = result
			completionHandler([result.cacheRecord].flatMap {$0})
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = clones?.value {
			
			let locationIDs = value.jumpClones?.map {$0.locationID} ?? []
			
			dataManager.locations(ids: Set(locationIDs)) { locations in
				let t = 3600 * 24 + (value.cloneJumpDate ?? .distantPast).timeIntervalSinceNow
				let s = String(format: NSLocalizedString("Clone jump availability: %@", comment: ""), t > 0 ? NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes) : NSLocalizedString("Now", comment: ""))
				
				var sections = [TreeNode]()
				
				sections.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
				                               nodeIdentifier: "Jump",
				                               title: NSLocalizedString("Next Clone Jump Availability", comment: "").uppercased(),
				                               subtitle: s))
				
				
				let invTypes = NCDatabase.sharedDatabase?.invTypes
				let list = [(NCDBAttributeID.intelligenceBonus, NSLocalizedString("Intelligence", comment: "")),
				            (NCDBAttributeID.memoryBonus, NSLocalizedString("Memory", comment: "")),
				            (NCDBAttributeID.perceptionBonus, NSLocalizedString("Perception", comment: "")),
				            (NCDBAttributeID.willpowerBonus, NSLocalizedString("Willpower", comment: "")),
				            (NCDBAttributeID.charismaBonus, NSLocalizedString("Charisma", comment: ""))]
				
				
				for clone in value.jumpClones ?? [] {
					
					let jumpCloneImplants = value.jumpCloneImplants?.filter {$0.jumpCloneID == clone.jumpCloneID}
					let implants = jumpCloneImplants?.flatMap { implant -> (NCDBInvType, Int)? in
						guard let type = invTypes?[implant.typeID] else {return nil}
						return (type, Int(type.allAttributes[NCDBAttributeID.implantness.rawValue]?.value ?? 100))
						}.sorted {$0.1 < $1.1} ?? []
					
					
					var rows = implants.map { (type, _) -> TreeRow in
						if let enhancer = list.first(where: { (type.allAttributes[$0.0.rawValue]?.value ?? 0) > 0 }) {
							return DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
							                      nodeIdentifier: "\(type.typeID).\(clone.jumpCloneID)",
								image: type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image,
								title: type.typeName?.uppercased(),
								subtitle: "\(enhancer.1) +\(Int(type.allAttributes[enhancer.0.rawValue]!.value))",
								accessoryType: .disclosureIndicator,
								route: Router.Database.TypeInfo(type))
						}
						else {
							return DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
							                      nodeIdentifier: "\(type.typeID).\(clone.jumpCloneID)",
								image: type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image,
								title: type.typeName?.uppercased(),
								accessoryType: .disclosureIndicator,
								route: Router.Database.TypeInfo(type))
						}
					}
					
					if rows.isEmpty {
						rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, nodeIdentifier: "NoImplants\(clone.jumpCloneID)", title: NSLocalizedString("No Implants Installed", comment: "").uppercased()))
					}
					sections.append(DefaultTreeSection(nodeIdentifier: "\(clone.jumpCloneID)", attributedTitle: locations[clone.locationID]?.displayName.uppercased(), children: rows))
				}
				
				if self.treeController?.content == nil {
					self.treeController?.content = RootNode(sections)
				}
				else {
					self.treeController?.content?.children = sections
				}
				self.tableView.backgroundView = nil
				completionHandler()
			}
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: clones?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	
}
