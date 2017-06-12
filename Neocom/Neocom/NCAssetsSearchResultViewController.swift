//
//  NCAssetsSearchResultViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCAssetsSearchResultViewController: UITableViewController, TreeControllerDelegate, UISearchResultsUpdating {
    
    @IBOutlet var treeController: TreeController!
    
	var items: [Int64: ESI.Assets.Asset]?
	var typeIDs: Set<Int>?
    var locations: [Int64: NCLocation]?
    var contents: [Int64: [ESI.Assets.Asset]]?
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        tableView.register([Prototype.NCHeaderTableViewCell.default,
                            Prototype.NCDefaultTableViewCell.default])
        treeController.delegate = self
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
            let engine = NCFittingEngine()
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
            }
        }
    }
    
    //MARK: - UISearchResultsUpdating
    
    private let gate = NCGate()
    
    public func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text,
            let items = items,
			let contents = contents,
            var typeIDs = typeIDs,
            !text.isEmpty
             else {
                return
        }

        
        let locations = self.locations ?? [:]
		
        gate.perform {
            NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext in
				
                var types = [Int: NCDBInvType]()

				var filtered: [ESI.Assets.Asset] = []
                
                let filteredLocations = Set(locations.filter {$0.value.displayName.string.range(of: text, options: [.caseInsensitive], range: nil, locale: nil) != nil}.map {$0.key})
				
				if typeIDs.count > 0 {
					let request = NSFetchRequest<NSDictionary>(entityName: "InvType")
					request.predicate = NSPredicate(format: "typeID in %@ AND (typeName CONTAINS [C] %@ OR group.groupName CONTAINS [C] %@ OR group.category.categoryName CONTAINS [C] %@)", typeIDs, text, text, text)
					request.propertiesToFetch = [NSEntityDescription.entity(forEntityName: "InvType", in: managedObjectContext)!.propertiesByName["typeID"]!]
					request.resultType = .dictionaryResultType
					let result = Set((try? managedObjectContext.fetch(request))?.flatMap {$0["typeID"] as? Int} ?? [])
					var array = Array(items.values.filter {
                        result.contains($0.typeID) || filteredLocations.contains($0.locationID)
                    })
					var array2 = array
					filtered.append(contentsOf: array)
					
					while !array.isEmpty {
						array = array.flatMap {items[$0.locationID]}
						filtered.append(contentsOf: array)
					}

					while !array2.isEmpty {
						array2 = Array(array2.flatMap {contents[$0.itemID]}.joined())
						filtered.append(contentsOf: array2)
					}

					
				}
				
				var items: [Int64: ESI.Assets.Asset] = [:]
				var filteredContents: [Int64: [ESI.Assets.Asset]] = [:]
				var typeIDs = Set<Int>()
				
				filtered.forEach {
					_ = (filteredContents[$0.locationID]?.append($0)) ?? (filteredContents[$0.locationID] = [$0])
					items[$0.itemID] = $0
					typeIDs.insert($0.typeID)
				}


				if typeIDs.count > 0 {
					let result: [NCDBInvType]? = managedObjectContext.fetch("InvType", where: "typeID in %@", typeIDs)
					result?.forEach {types[Int($0.typeID)] = $0}
				}

                func row(asset: ESI.Assets.Asset) -> DefaultTreeRow {
                    let type = types[asset.typeID]
                    let typeName = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
                    let title: NSAttributedString
                    if let qty = asset.quantity, qty > 1 {
                        title = typeName + (" x" + NCUnitFormatter.localizedString(from: qty, unit: .none, style: .full)) * [NSForegroundColorAttributeName: UIColor.caption]
                    }
                    else {
                        title = NSAttributedString(string: typeName)
                    }
                    var rows = filteredContents[asset.itemID]?.map {row(asset: $0)} ?? []
                    rows.sort { ($0.0.attributedTitle?.string ?? "") < ($0.1.attributedTitle?.string ?? "") }
                    
                    let subtitle = rows.count > 0 ? NCUnitFormatter.localizedString(from: rows.count, unit: .none, style: .full) + " " + NSLocalizedString("items", comment: "") : nil
                    
                    let route: Route?
                    if let typeID = type?.typeID {
                        route = Router.Database.TypeInfo(Int(typeID))
                    }
                    else {
                        route = nil
                    }
                    
                    let hasLoadout = type?.group?.category?.categoryID == Int32(NCDBCategoryID.ship.rawValue) && !rows.isEmpty
                    
                    let assetRow = DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.default,
                                                  nodeIdentifier: "\(asset.itemID)",
                        image: type?.icon?.image?.image,
                        attributedTitle: title,
                        subtitle: subtitle,
                        accessoryType: hasLoadout ? .detailButton : .none,
                        route: route,
                        object: asset)
                    assetRow.children = rows
                    return assetRow
                }
                
                var sections = [DefaultTreeSection]()
                for locationID in Set(locations.keys).subtracting(Set(items.keys)) {
                    guard var rows = filteredContents[locationID]?.map ({row(asset: $0)}) else {continue}
                    
                    rows.sort { ($0.0.attributedTitle?.string ?? "") < ($0.1.attributedTitle?.string ?? "") }
                    
                    let location = locations[locationID]
                    let title = location?.displayName ?? NSAttributedString(string: NSLocalizedString("Unknown Location", comment: ""))
                    let nodeIdentifier = location?.solarSystemName ?? "~"
                    
                    sections.append(DefaultTreeSection(nodeIdentifier: nodeIdentifier, attributedTitle: title, children: rows))
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
                    self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
                }
            }
            
        }
        

    }
}
