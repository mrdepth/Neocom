//
//  NCJumpClonesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCJumpCloneRow: NCTreeRow {
	let title: String?
	let subtitle: String?
	let image: UIImage?
	
	init(cellIdentifier: String, title: String?, subtitle: String?, image: UIImage?) {
		self.title = title
		self.subtitle = subtitle
		self.image = image
		super.init(cellIdentifier: cellIdentifier)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as? NCTableViewDefaultCell
		cell?.titleLabel?.text = title
		cell?.subtitleLabel?.text = subtitle
		cell?.imageView?.image = image
	}
}

class NCJumpClonesViewController: UITableViewController, NCTreeControllerDelegate {
	@IBOutlet weak var treeController: NCTreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		treeController.childrenKeyPath = "children"
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController.content == nil {
			reload()
		}
	}
	
	//MARK: NCTreeControllerDelegate
	
	func treeController(_ treeController: NCTreeController, cellIdentifierForItem item: AnyObject) -> String {
		return (item as! NCTreeNode).cellIdentifier
	}
	
	func treeController(_ treeController: NCTreeController, configureCell cell: UITableViewCell, withItem item: AnyObject) {
		(item as! NCTreeNode).configure(cell: cell)
	}
	
	//MARK: Private
	
	@objc private func refresh() {
		let progress = NCProgressHandler(totalUnitCount: 1)
		progress.progress.becomeCurrent(withPendingUnitCount: 1)
		reload(cachePolicy: .reloadIgnoringLocalCacheData) {
			self.refreshControl?.endRefreshing()
		}
		progress.progress.resignCurrent()
	}
	
	private var observer: NCManagedObjectObserver?
	
	private func process(_ value: ESClones, dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		var locations = [Int64]()
		for jumpClone in value.jumpClones {
			locations.append(jumpClone.location.locationID)
		}
		
		dataManager.locations(ids: locations) { locations in
			
			var sections = [NCTreeNode]()
			
			let t = 3600 * 24 + value.lastJumpDate.timeIntervalSinceNow
			sections.append(NCJumpCloneRow(cellIdentifier: "Cell",
			                               title: NSLocalizedString("NEXT CLONE JUMP AVAILABILITY", comment: ""),
			                               subtitle: String(format: NSLocalizedString("Clone jump availability: %@", comment: ""), t > 0 ? NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes) : NSLocalizedString("Now", comment: "")),
			                               image: UIImage(named: "jumpclones")))
			
			let invTypes = NCDatabase.sharedDatabase?.invTypes
			let attributeIDs = [NCDBAttributeID.intelligenceBonus, NCDBAttributeID.memoryBonus, NCDBAttributeID.perceptionBonus, NCDBAttributeID.willpowerBonus, NCDBAttributeID.charismaBonus]
			
			let titles = [NCDBAttributeID.intelligenceBonus:	NSLocalizedString("Intelligence", comment: ""),
			              NCDBAttributeID.memoryBonus:			NSLocalizedString("Memory", comment: ""),
			              NCDBAttributeID.perceptionBonus:		NSLocalizedString("Perception", comment: ""),
			              NCDBAttributeID.willpowerBonus:		NSLocalizedString("Willpower", comment: ""),
			              NCDBAttributeID.charismaBonus:		NSLocalizedString("Charisma", comment: ""),
			              ]
			
			for jumpClone in value.jumpClones {
				var rows = [NCJumpCloneRow]()
				
				for case let implant in jumpClone.implants.map({ invTypes?[$0]}) {
					guard let attributes = implant?.allAttributes else {continue}
					for attributeID in attributeIDs {
						if let bonus = attributes[attributeID.rawValue]?.value, bonus > 0 {
							rows.append(NCJumpCloneRow(cellIdentifier: "Cell",
							                           title: implant?.typeName,
							                           subtitle: "\(titles[attributeID]!) +\(Int(bonus))",
								image: implant?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image))
						}
					}
				}
				if rows.count == 0 {
					rows.append(NCJumpCloneRow(cellIdentifier: "PlaceholderCell", title: NSLocalizedString("NO IMPLANTS INSTALLED", comment: ""), subtitle: nil, image: nil))
				}
				sections.append(NCTreeSection(cellIdentifier: "NCTableViewHeaderCell", nodeIdentifier: nil, attributedTitle: locations[jumpClone.location.locationID]?.displayName.uppercased(), children: rows))
			}
			
			self.treeController.content = sections
			self.tableView.backgroundView = nil
			self.treeController.reloadData()
			completionHandler?()
			
		}
	}
	
	private func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		if let account = NCAccount.current {
			let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
			
			dataManager.clones { result in
				switch result {
				case let .success(value: value, cacheRecordID: recordID):
					self.observer = NCManagedObjectObserver(managedObjectID: recordID) { [weak self] _, _ in
						guard let record = (try? NCCache.sharedCache?.viewContext.existingObject(with: recordID)) as? NCCacheRecord else {return}
						guard let value = record.data?.data as? ESClones else {return}
						self?.process(value, dataManager: dataManager, completionHandler: nil)
					}
					self.process(value, dataManager: dataManager, completionHandler: completionHandler)
				case let .failure(error):
					if self.treeController.content == nil {
						self.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
					}
				}
			}
			
		}
	}
}
