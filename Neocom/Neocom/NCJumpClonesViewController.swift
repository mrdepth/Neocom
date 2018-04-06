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
		accountChangeAction = .reload
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.attribute,
		                    Prototype.NCDefaultTableViewCell.placeholder])
	}

	private var clones: CachedValue<ESI.Clones.JumpClones>?
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		return dataManager.clones().then(on: .main) { result -> [NCCacheRecord] in
			self.clones = result
			return [result.cacheRecord]
		}
	}
	
	override func content() -> Future<TreeNode?> {
		return OperationQueue(qos: .utility).async { () -> TreeNode? in
			guard let value = self.clones?.value else {throw NCTreeViewControllerError.noResult}
			let locationIDs = value.jumpClones.compactMap {$0.locationID}
			let locations = try? self.dataManager.locations(ids: Set(locationIDs)).get()
			return try NCDatabase.sharedDatabase!.performTaskAndWait { managedObjectContext -> TreeNode? in
				let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
				
				let t = 3600 * 24 + (value.lastCloneJumpDate ?? .distantPast).timeIntervalSinceNow
				let s = String(format: NSLocalizedString("Clone jump availability: %@", comment: ""), t > 0 ? NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes) : NSLocalizedString("Now", comment: ""))
				
				var sections = [TreeNode]()
				
				sections.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
											   nodeIdentifier: "Jump",
											   title: NSLocalizedString("Next Clone Jump Availability", comment: "").uppercased(),
											   subtitle: s))
				
				let list = [(NCDBAttributeID.intelligenceBonus, NSLocalizedString("Intelligence", comment: "")),
							(NCDBAttributeID.memoryBonus, NSLocalizedString("Memory", comment: "")),
							(NCDBAttributeID.perceptionBonus, NSLocalizedString("Perception", comment: "")),
							(NCDBAttributeID.willpowerBonus, NSLocalizedString("Willpower", comment: "")),
							(NCDBAttributeID.charismaBonus, NSLocalizedString("Charisma", comment: ""))]
				
				
				for (i, clone) in value.jumpClones.enumerated() {
					let implants = clone.implants.compactMap { implant -> (NCDBInvType, Int)? in
						guard let type = invTypes[implant] else {return nil}
						return (type, Int(type.allAttributes[NCDBAttributeID.implantness.rawValue]?.value ?? 100))
						}.sorted {$0.1 < $1.1}
					
					var rows = implants.map { (type, _) -> TreeRow in
						if let enhancer = list.first(where: { (type.allAttributes[$0.0.rawValue]?.value ?? 0) > 0 }) {
							return DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
												  nodeIdentifier: "\(type.typeID).\(i)",
								image: type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image,
								title: type.typeName?.uppercased(),
								subtitle: "\(enhancer.1) +\(Int(type.allAttributes[enhancer.0.rawValue]!.value))",
								accessoryType: .disclosureIndicator,
								route: Router.Database.TypeInfo(type))
						}
						else {
							return DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
												  nodeIdentifier: "\(type.typeID).\(i)",
								image: type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image,
								title: type.typeName?.uppercased(),
								accessoryType: .disclosureIndicator,
								route: Router.Database.TypeInfo(type))
						}
					}
					
					if rows.isEmpty {
						rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, nodeIdentifier: "NoImplants\(i)", title: NSLocalizedString("No Implants Installed", comment: "").uppercased()))
					}
					if let title = locations?[clone.locationID]?.displayName.uppercased() {
						sections.append(DefaultTreeSection(nodeIdentifier: "\(i)", attributedTitle: title, children: rows))
					}
					else {
						sections.append(DefaultTreeSection(nodeIdentifier: "\(i)", title: NSLocalizedString("Unknown Location", comment: ""), children: rows))
					}
				}
				guard !sections.isEmpty else {throw NCTreeViewControllerError.noResult}
				return RootNode(sections)
			}
		}
	}
}
