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
import Futures

class NCAssetsSearchResultViewController: NCTreeViewController, UISearchResultsUpdating {
    
	var items: [Int64: NCAsset]?
	var typeIDs: Set<Int>?
    var locations: [Int64: NCLocation]?
    var contents: [Int64: [NCAsset]]?
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.image,
		                    Prototype.NCDefaultTableViewCell.default])
    }
	
	private let root = TreeNode()
	
	override func content() -> Future<TreeNode?> {
		return .init(root)
	}

	
    //MARK: - UISearchResultsUpdating
    
    private let gate = NCGate()
    
    public func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text,
            let items = items,
			let contents = contents,
            let typeIDs = typeIDs,
            !text.isEmpty
             else {
                return
        }

        
        let locations = self.locations ?? [:]
		
        gate.perform {
            NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext in
				
                var types = [Int: NCDBInvType]()

				var filtered: [NCAsset] = []
                
                let filteredLocations = Set(locations.filter {$0.value.displayName.string.range(of: text, options: [.caseInsensitive], range: nil, locale: nil) != nil}.map {$0.key})
				
				if typeIDs.count > 0 {
					let request = NSFetchRequest<NSDictionary>(entityName: "InvType")
					request.predicate = NSPredicate(format: "typeID in %@ AND (typeName CONTAINS [C] %@ OR group.groupName CONTAINS [C] %@ OR group.category.categoryName CONTAINS [C] %@)", typeIDs, text, text, text)
					request.propertiesToFetch = [NSEntityDescription.entity(forEntityName: "InvType", in: managedObjectContext)!.propertiesByName["typeID"]!]
					request.resultType = .dictionaryResultType
					let result = Set((try? managedObjectContext.fetch(request))?.compactMap {$0["typeID"] as? Int} ?? [])
					var array = Array(items.values.filter {
                        result.contains($0.typeID) || filteredLocations.contains($0.locationID)
                    })
					var array2 = array
					filtered.append(contentsOf: array)
					
					while !array.isEmpty {
						array = array.compactMap {items[$0.locationID]}
						filtered.append(contentsOf: array)
					}

					while !array2.isEmpty {
						array2 = Array(array2.compactMap {contents[$0.itemID]}.joined())
						filtered.append(contentsOf: array2)
					}

					
				}
				
				var items: [Int64: NCAsset] = [:]
				var filteredContents: [Int64: [NCAsset]] = [:]
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

                var sections = [DefaultTreeSection]()
                for locationID in Set(locations.keys).subtracting(Set(items.keys)) {
                    guard var rows = filteredContents[locationID]?.map ({NCAssetRow(asset: $0, contents: filteredContents, types: types)}) else {continue}
                    
                    rows.sort { ($0.attributedTitle?.string ?? "") < ($1.attributedTitle?.string ?? "") }
                    
                    let location = locations[locationID]
                    let title = location?.displayName ?? NSAttributedString(string: NSLocalizedString("Unknown Location", comment: ""))
                    let nodeIdentifier = "\(locationID)"
                    
                    sections.append(DefaultTreeSection(nodeIdentifier: nodeIdentifier, attributedTitle: title.uppercased(), children: rows))
                }
                sections.sort {$0.nodeIdentifier! < $1.nodeIdentifier!}
                
                DispatchQueue.main.async {
					self.root.children = sections
                    self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
                }
            }
            
        }
        

    }
}
