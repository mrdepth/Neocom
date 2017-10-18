//
//  NCKillmailInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCKillmailItemRow: TreeRow {
	let typeID: Int
	let quantityDropped: Int64
	let quantityDestroyed: Int64
	let flag: ESI.Assets.Asset.Flag?
	
	init(item: NCItem) {
		typeID = item.itemTypeID
		quantityDropped = item.quantityDropped ?? 0
		quantityDestroyed = item.quantityDestroyed ?? 0
		flag = ESI.Assets.Asset.Flag(item.flag)

		super.init(prototype: Prototype.NCDefaultTableViewCell.default, route: Router.Database.TypeInfo(item.itemTypeID))
		children = item.getItems()?.map{NCKillmailItemRow(item: $0)} ?? []
	}
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.typeID]
	}()

	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.accessoryType = .disclosureIndicator
		
		cell.backgroundColor = quantityDropped > 0 ? UIColor.separator : UIColor.cellBackground
		
		switch (quantityDropped, quantityDestroyed) {
		case let (dropped, destroyed) where dropped > 0 && destroyed > 0:
			cell.subtitleLabel?.text = String(format: NSLocalizedString("Dropped: %@   Destroyed: %@", comment: ""), NCUnitFormatter.localizedString(from: Double(dropped), unit: .none, style: .full), NCUnitFormatter.localizedString(from: Double(destroyed), unit: .none, style: .full))
		case let (dropped, destroyed) where dropped > 0 && destroyed == 0:
			cell.subtitleLabel?.text = String(format: NSLocalizedString("Dropped: %@", comment: ""), NCUnitFormatter.localizedString(from: Double(dropped), unit: .none, style: .full))
		case let (dropped, destroyed) where dropped == 0 && destroyed > 0:
			cell.subtitleLabel?.text = String(format: NSLocalizedString("Destroyed: %@", comment: ""), NCUnitFormatter.localizedString(from: Double(destroyed), unit: .none, style: .full))
		default:
			cell.subtitleLabel?.text = " "
		}
	}
}

class NCKillmailItemSection: TreeSection {
	let title: String
	let image: UIImage
	
	init(title: String, image: UIImage, rows: [NCKillmailItemRow]) {
		self.title = title
		self.image = image
		super.init(prototype: Prototype.NCHeaderTableViewCell.image)
		children = rows
		isExpandable = false
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.titleLabel?.text = title
		cell.iconView?.image = image
	}
	
	override var hashValue: Int {
		return title.hash
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCKillmailItemSection)?.hashValue == hashValue
	}
}

class NCKillmailVictimRow: NCContactRow {
	let character: NCContact?
	let corporation: NCContact?
	let alliance: NCContact?
	
	init(character: NCContact?, corporation: NCContact?, alliance: NCContact?, dataManager: NCDataManager) {
		self.character = character
		self.corporation = corporation
		self.alliance = alliance
		let contact = character ?? corporation ?? alliance
		super.init(prototype: Prototype.NCContactTableViewCell.default, contact: contact, dataManager: dataManager)
		if let contact = contact {
			route = Router.KillReports.ContactReports(contact: contact)
		}
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCContactTableViewCell else {return}
		switch (corporation?.name, alliance?.name) {
		case let (a?, b?):
			cell.subtitleLabel?.text = "\(a) / \(b)"
		case let (a?, nil):
			cell.subtitleLabel?.text = a
		case let (nil, b):
			cell.subtitleLabel?.text = b
		default:
			cell.subtitleLabel = nil
		}
		cell.accessoryType = .disclosureIndicator
	}
}



class NCKillmailInfoViewController: NCTreeViewController {
	
	var killmail: NCKillmail?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.noImage,
		                    Prototype.NCContactTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.image,
		                    Prototype.NCKillmailAttackerTableViewCell.default,
		                    Prototype.NCKillmailAttackerTableViewCell.npc,
		                    Prototype.NCHeaderTableViewCell.default])
		
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let killmail = killmail {
			tableView.backgroundView = nil
			let dataManager = self.dataManager
			
			let progress = Progress(totalUnitCount: 3)
			
			progress.perform {
				NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
					let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
					
					var sections = [TreeNode]()
					
					var rows = [TreeNode]()
					let victim = killmail.getVictim()
					
					let location: NSAttributedString? = {
						guard let solarSystem = NCDBMapSolarSystem.mapSolarSystems(managedObjectContext: managedObjectContext)[killmail.solarSystemID] else {return nil}
						guard let region = solarSystem.constellation?.region?.regionName else {return nil}
						return NCLocation(solarSystem).displayName + " / " + region
					}()
					
					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
					                           nodeIdentifier: "Location",
					                           attributedTitle: location ?? NSAttributedString(string: NSLocalizedString("Unknown Location", comment: "")),
					                           subtitle: DateFormatter.localizedString(from: killmail.killmailTime, dateStyle: .medium, timeStyle: .medium),
					                           accessoryType: .disclosureIndicator,
					                           route: Router.KillReports.RelatedKills(killmail: killmail)))
					//route: Router.KillReports.SolarSystemReports(solarSystemID: killmail.solarSystemID)))
					
					let ship = invTypes[victim.shipTypeID]
					let shipRow = DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.default,
					                             nodeIdentifier: "VictimShip", image: ship?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image,
					                             title: ship?.typeName ?? NSLocalizedString("Unknown Type", comment: ""), //shipTitle(ship),
						subtitle: NSLocalizedString("Damage taken:", comment: "") + " " + NCUnitFormatter.localizedString(from: victim.damageTaken, unit: .none, style: .full),
						accessoryType: ship != nil ? .disclosureIndicator : .none,
						route: ship != nil ? Router.Database.TypeInfo(ship!.objectID) : nil)
					
					rows.append(shipRow)
					
					if let items = killmail.getItems()?.map ({return NCKillmailItemRow(item: $0)}) {
						var hi = [NCKillmailItemRow]()
						var med = [NCKillmailItemRow]()
						var low = [NCKillmailItemRow]()
						var rig = [NCKillmailItemRow]()
						var subsystem = [NCKillmailItemRow]()
						var drone = [NCKillmailItemRow]()
						var cargo = [NCKillmailItemRow]()
						
						items.forEach {
							switch $0.flag {
							case .hiSlot0?, .hiSlot1?, .hiSlot2?, .hiSlot3?, .hiSlot4?, .hiSlot5?, .hiSlot6?, .hiSlot7?:
								hi.append($0)
							case .medSlot0?, .medSlot1?, .medSlot2?, .medSlot3?, .medSlot4?, .medSlot5?, .medSlot6?, .medSlot7?:
								med.append($0)
							case .loSlot0?, .loSlot1?, .loSlot2?, .loSlot3?, .loSlot4?, .loSlot5?, .loSlot6?, .loSlot7?:
								low.append($0)
							case .rigSlot0?, .rigSlot1?, .rigSlot2?, .rigSlot3?, .rigSlot4?, .rigSlot5?, .rigSlot6?, .rigSlot7?:
								rig.append($0)
							case .subSystemSlot0?, .subSystemSlot1?, .subSystemSlot2?, .subSystemSlot3?, .subSystemSlot4?, .subSystemSlot5?, .subSystemSlot6?, .subSystemSlot7?:
								subsystem.append($0)
							case .droneBay?, .fighterBay?, .fighterTube0?, .fighterTube1?, .fighterTube2?, .fighterTube3?, .fighterTube4?:
								drone.append($0)
							default:
								cargo.append($0)
							}
						}
						
						var sections = [TreeNode]()
						
						if !hi.isEmpty {
							sections.append(NCKillmailItemSection(title: NSLocalizedString("Hi Slot", comment: "").uppercased(), image: #imageLiteral(resourceName: "slotHigh"), rows: hi))
						}
						if !med.isEmpty {
							sections.append(NCKillmailItemSection(title: NSLocalizedString("Med Slot", comment: "").uppercased(), image: #imageLiteral(resourceName: "slotMed"), rows: med))
						}
						if !low.isEmpty {
							sections.append(NCKillmailItemSection(title: NSLocalizedString("Low Slot", comment: "").uppercased(), image: #imageLiteral(resourceName: "slotLow"), rows: low))
						}
						if !rig.isEmpty {
							sections.append(NCKillmailItemSection(title: NSLocalizedString("Rig Slot", comment: "").uppercased(), image: #imageLiteral(resourceName: "slotRig"), rows: rig))
						}
						if !subsystem.isEmpty {
							sections.append(NCKillmailItemSection(title: NSLocalizedString("Subsystem Slot", comment: "").uppercased(), image: #imageLiteral(resourceName: "slotSubsystem"), rows: subsystem))
						}
						if !drone.isEmpty {
							sections.append(NCKillmailItemSection(title: NSLocalizedString("Drones", comment: "").uppercased(), image: #imageLiteral(resourceName: "drone"), rows: drone))
						}
						if !cargo.isEmpty {
							sections.append(NCKillmailItemSection(title: NSLocalizedString("Cargo", comment: "").uppercased(), image: #imageLiteral(resourceName: "cargoBay"), rows: cargo))
						}
						
						if !sections.isEmpty {
							shipRow.children = sections
						}
					}
					
					let victimSection = DefaultTreeSection(nodeIdentifier: "Victim", attributedTitle: NSLocalizedString("Victim", comment: "").uppercased() * [:], children: rows)
					sections.append(victimSection)
					
					var ids = Set<Int64>()
					
					ids.formUnion([victim.characterID, victim.corporationID, victim.allianceID].flatMap{$0}.map{Int64($0)})
					ids.formUnion(killmail.getAttackers().map { [$0.characterID, $0.corporationID, $0.allianceID].flatMap{$0}.map{Int64($0)}}.joined())
					
					ids.remove(0)
					
					let dispatchGroup = DispatchGroup()
					
					var contacts: [Int64: NCContact]?
					
					progress.perform {
						if !ids.isEmpty {
							dispatchGroup.enter()
							dataManager.contacts(ids: ids) { result in
								contacts = result
								
								dispatchGroup.leave()
							}
						}
					}
					
					var typeIDs = [Int: Int64]()
					typeIDs[victim.shipTypeID] = (typeIDs[victim.shipTypeID] ?? 0) + 1
					killmail.getItems()?.forEach {
						typeIDs[$0.itemTypeID] = (typeIDs[$0.itemTypeID] ?? 0) + ($0.quantityDropped ?? 0) + ($0.quantityDestroyed ?? 0)
						$0.getItems()?.forEach {
							typeIDs[$0.itemTypeID] = (typeIDs[$0.itemTypeID] ?? 0) + ($0.quantityDropped ?? 0) + ($0.quantityDestroyed ?? 0)
						}
					}
					
					var cost: Double = 0
					
					progress.perform {
						if !typeIDs.isEmpty {
							dispatchGroup.enter()
							dataManager.prices(typeIDs: Set(typeIDs.keys)) { result in
								typeIDs.forEach {
									cost += Double((result[$0.key] ?? 0)) * Double($0.value)
								}
								
								dispatchGroup.leave()
							}
						}
					}
					
					dispatchGroup.notify(queue: .main) {
						victimSection.children.insert(NCKillmailVictimRow(character: contacts?[Int64(victim.characterID ?? 0)],
						                                                  corporation: contacts?[Int64(victim.corporationID ?? 0)],
						                                                  alliance: contacts?[Int64(victim.allianceID ?? 0)], dataManager: dataManager), at: 0)
						if cost > 0 {
							victimSection.attributedTitle = NSLocalizedString("Victim", comment: "").uppercased() + " (\((NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .full))))" * [NSAttributedStringKey.foregroundColor: UIColor.white]
						}
						
						
						let attackers = killmail.getAttackers().sorted { (a, b) -> Bool in
							if a.finalBlow && !b.finalBlow {
								return true
							}
							else if !a.finalBlow && b.finalBlow {
								return false
							}
							else {
								return a.damageDone > b.damageDone
							}
							}.map {NCKillmailAttackerRow(attacker: $0,
							                             character: contacts?[Int64($0.characterID ?? 0)],
							                             corporation: contacts?[Int64($0.corporationID ?? 0)],
							                             alliance: contacts?[Int64($0.allianceID ?? 0)],
							                             dataManager: dataManager)}
						
						if !attackers.isEmpty {
							sections.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.default,
							                                   nodeIdentifier: "Attackers", title: NSLocalizedString("Attackers", comment: "").uppercased(),
							                                   children: attackers))
						}
						
						self.treeController?.content = RootNode(sections)
					}
					
				}
			}
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
		

	}
	
	@IBAction func onFitting(_ sender: Any) {
		guard let killmail = self.killmail else {return}
		
		Router.Fitting.Editor(killmail: killmail).perform(source: self, sender: sender)
		
		/*UIApplication.shared.beginIgnoringInteractionEvents()
		let engine = NCFittingEngine()
		engine.perform {
			
			let fleet = NCFittingFleet(killmail: killmail, engine: engine)
			DispatchQueue.main.async {
				UIApplication.shared.endIgnoringInteractionEvents()
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
