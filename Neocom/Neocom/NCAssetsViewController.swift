//
//  NCAssetsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCAssetRow: DefaultTreeRow {
	
	init(asset: ESI.Assets.Asset, contents: [Int64: [ESI.Assets.Asset]], types: [Int: NCDBInvType]) {
		let type = types[asset.typeID]
		let typeName = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		let title: NSAttributedString
		if let qty = asset.quantity, qty > 1 {
			title = typeName + (" x" + NCUnitFormatter.localizedString(from: qty, unit: .none, style: .full)) * [NSForegroundColorAttributeName: UIColor.caption]
		}
		else {
			title = NSAttributedString(string: typeName)
		}
		
		var children: [TreeNode] = []
		
		let subtitle: String?
		
		if let nested = contents[asset.itemID], !contents.isEmpty {
			var map: [NCItemFlag:[DefaultTreeRow]] = [:]
			var rows = [DefaultTreeRow]()
			
			nested.forEach {
				let assetRow = NCAssetRow(asset: $0, contents: contents, types: types)
				if let flag = NCItemFlag(flag: $0.locationFlag) {
					_ = (map[flag]?.append(assetRow)) ?? (map[flag] = [assetRow])
				}
				else {
					rows.append(assetRow)
				}
			}
			
			rows.sort { ($0.0.attributedTitle?.string ?? "") < ($0.1.attributedTitle?.string ?? "") }
			children = rows
			
			let sections = map.sorted {$0.key.rawValue < $1.key.rawValue}.map { i -> DefaultTreeSection in
				let section = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.image,
				                                 nodeIdentifier: "\(asset.itemID).\(i.key.rawValue)",
					image: i.key.image,
					title: i.key.title?.uppercased(),
					children: i.value.sorted { ($0.0.attributedTitle?.string ?? "") < ($0.1.attributedTitle?.string ?? "") })
				section.isExpandable = false
				return section
			}
			
			children.append(contentsOf: sections as [TreeNode])
			subtitle = !nested.isEmpty ? NCUnitFormatter.localizedString(from: nested.count, unit: .none, style: .full) + " " + NSLocalizedString("items", comment: "") : nil
		}
		else {
			subtitle = nil
		}
		
		
		
		let route: Route?
		if let typeID = type?.typeID {
			route = Router.Database.TypeInfo(Int(typeID))
		}
		else {
			route = nil
		}
		let hasLoadout = type?.group?.category?.categoryID == Int32(NCDBCategoryID.ship.rawValue) && !children.isEmpty
		
		
		super.init(prototype: Prototype.NCDefaultTableViewCell.default,
		           nodeIdentifier: "\(asset.itemID)",
			image: type?.icon?.image?.image,
			attributedTitle: title,
			subtitle: subtitle,
			accessoryType: hasLoadout ? .detailButton : .none,
			route: route,
			object: asset)
		self.children = children
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		cell.indentationWidth = 16
	}
}

class NCAssetsViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!

	override func viewDidLoad() {
		super.viewDidLoad()
		
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

		registerRefreshable()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.image,
		                    Prototype.NCDefaultTableViewCell.default])
		treeController.delegate = self
		
		setupSearchController()
		
		reload()
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.route?.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		if let row = node as? DefaultTreeRow, let asset = row.object as? ESI.Assets.Asset, let contents = contents {
			Router.Fitting.Editor(asset: asset, contents: contents).perform(source: self, view: treeController.cell(for: node))
			
            /*let engine = NCFittingEngine()
            engine.perform {
                let fleet = NCFittingFleet(asset: asset, contents: contents, engine: engine)
                DispatchQueue.main.async {
                    if let account = NCAccount.current {
                        fleet.active?.setSkills(from: account) { [weak self]  _ in
                            guard let strongSelf = self else {return}
                            Router.Fitting.Editor(fleet: fleet, engine: engine).perform(source: strongSelf)
                        }
                    }
                    else {
                        fleet.active?.setSkills(level: 5) { [weak self] _ in
                            guard let strongSelf = self else {return}
                            Router.Fitting.Editor(fleet: fleet, engine: engine).perform(source: strongSelf)
                        }
                    }
                }
            }*/
		}
	}
	
	
	//MARK: - NCRefreshable
	
	private var observer: NCManagedObjectObserver?
	private var assets: NCCachedResult<[ESI.Assets.Asset]>?
	private var locations: [Int64: NCLocation]?
	var contents: [Int64: [ESI.Assets.Asset]]?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		
		let progress = Progress(totalUnitCount: 1)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		
		progress.perform {
			dataManager.assets { result in
				self.assets = result
				
				switch result {
				case let .success(_, record):
					if let record = record {
						self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
							self?.reloadLocations(dataManager: dataManager) {
								self?.reloadSections()
							}
						}
					}
					
					self.reloadLocations(dataManager: dataManager) {
						self.reloadSections {
							completionHandler?()
						}
					}
				case .failure:
					self.reloadSections {
						completionHandler?()
					}
				}
				
				
			}
		}
	}
	
	private func reloadLocations(dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		guard let value = assets?.value else {
			completionHandler?()
			return
		}
		var locationIDs = Set(value.map {$0.locationID})
		let itemIDs = Set(value.map {$0.itemID})
		locationIDs.subtract(itemIDs)
		
		guard !locationIDs.isEmpty else {
			completionHandler?()
			return
		}
		
		dataManager.locations(ids: locationIDs) { [weak self] result in
			self?.locations = result
			completionHandler?()
		}
		
	}
	
	private func reloadSections(completionHandler: (() -> Void)? = nil) {
		if let value = assets?.value {
			tableView.backgroundView = nil
			let locations = self.locations ?? [:]
			
			NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
				var items: [Int64: ESI.Assets.Asset] = [:]
				var contents: [Int64: [ESI.Assets.Asset]] = [:]
				var typeIDs = Set<Int>()
				
				value.forEach {
					_ = (contents[$0.locationID]?.append($0)) ?? (contents[$0.locationID] = [$0])
					items[$0.itemID] = $0
					typeIDs.insert($0.typeID)
				}
				
				var types = [Int: NCDBInvType]()
				if typeIDs.count > 0 {
					let result: [NCDBInvType]? = managedObjectContext.fetch("InvType", where: "typeID in %@", typeIDs)
					result?.forEach {types[Int($0.typeID)] = $0}
				}
				
				var sections = [DefaultTreeSection]()
				for locationID in Set(locations.keys).subtracting(Set(items.keys)) {
					guard var rows = contents[locationID]?.map ({NCAssetRow(asset: $0, contents: contents, types: types)}) else {continue}
					
					rows.sort { ($0.0.attributedTitle?.string ?? "") < ($0.1.attributedTitle?.string ?? "") }
					
					let location = locations[locationID]
					let title = location?.displayName ?? NSAttributedString(string: NSLocalizedString("Unknown Location", comment: ""))
					let nodeIdentifier = "\(location?.solarSystemName ?? "")\(locationID)"
					
					let section = DefaultTreeSection(nodeIdentifier: nodeIdentifier, attributedTitle: title.uppercased(), children: rows)
					section.isExpanded = false
					sections.append(section)
				}
				sections.sort {$0.nodeIdentifier! < $1.nodeIdentifier!}

				DispatchQueue.main.async {
                    
					if self.treeController.content == nil {
						let root = TreeNode()
						root.children = sections
						self.treeController.content = root
					}
					else {
						self.treeController.content?.children = sections
					}
					self.contents = contents
					self.searchResultsController?.items = items
					self.searchResultsController?.contents = contents
					self.searchResultsController?.locations = locations
					self.searchResultsController?.typeIDs = typeIDs
//                    self.searchResultsController?.sections = copySections
					if let searchController = self.searchController, searchController.isActive {
						self.searchResultsController?.updateSearchResults(for: searchController)
					}
					self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
					completionHandler?()
				}
			}
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: assets?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler?()
		}
	}
	
	private var searchController: UISearchController?
	private var searchResultsController: NCAssetsSearchResultViewController?

	private func setupSearchController() {
		searchResultsController = self.storyboard?.instantiateViewController(withIdentifier: "NCAssetsSearchResultViewController") as? NCAssetsSearchResultViewController
		searchController = UISearchController(searchResultsController: searchResultsController )
		searchController?.searchBar.searchBarStyle = UISearchBarStyle.default
		searchController?.searchResultsUpdater = searchResultsController
		searchController?.searchBar.barStyle = UIBarStyle.black
		searchController?.hidesNavigationBarDuringPresentation = false
		tableView.backgroundView = UIView()
		tableView.tableHeaderView = searchController?.searchBar
		definesPresentationContext = true
		
	}
}
