//
//  NCCharacterSheetViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCCharacterAttributesSection: DefaultTreeSection {
	
	init(attributes: NCCharacterAttributes, nodeIdentifier: String? = nil, title: String? = nil) {
		var rows = [TreeNode]()
		rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Intelligence", image: #imageLiteral(resourceName: "intelligence"), title: NSLocalizedString("Intelligence", comment: "").uppercased(), subtitle: "\(attributes.intelligence) \(NSLocalizedString("points", comment: ""))"))
		rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Memory", image: #imageLiteral(resourceName: "memory"), title: NSLocalizedString("Memory", comment: "").uppercased(), subtitle: "\(attributes.memory) \(NSLocalizedString("points", comment: ""))"))
		rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Perception", image: #imageLiteral(resourceName: "perception"), title: NSLocalizedString("Perception", comment: "").uppercased(), subtitle: "\(attributes.perception) \(NSLocalizedString("points", comment: ""))"))
		rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Willpower", image: #imageLiteral(resourceName: "willpower"), title: NSLocalizedString("Willpower", comment: "").uppercased(), subtitle: "\(attributes.willpower) \(NSLocalizedString("points", comment: ""))"))
		rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Charisma", image: #imageLiteral(resourceName: "charisma"), title: NSLocalizedString("Charisma", comment: "").uppercased(), subtitle: "\(attributes.charisma) \(NSLocalizedString("points", comment: ""))"))
		super.init(nodeIdentifier: nodeIdentifier, title: title, children: rows)
	}
}

class NCCharacterSheetViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		registerRefreshable()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.attribute,
		                    Prototype.NCDefaultTableViewCell.placeholder])
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		reload()
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.route?.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
	//MARK: - NCRefreshable
	
	private var observer: NCManagedObjectObserver?
	private var characterDetailsObserver: NCManagedObjectObserver?

	private var character: NCCachedResult<ESI.Character.Information>?
	private var corporation: NCCachedResult<ESI.Corporation.Information>?
	private var alliance: NCCachedResult<ESI.Alliance.Information>?
	private var clones: NCCachedResult<EVE.Char.Clones>?
	private var skills: NCCachedResult<ESI.Skills.CharacterSkills>?
	private var wallets: NCCachedResult<[ESI.Wallet.Balance]>?
	private var characterImage: NCCachedResult<UIImage>?
	private var corporationImage: NCCachedResult<UIImage>?
	private var allianceImage: NCCachedResult<UIImage>?
	
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		title = account.characterName
		
		let dispatchGroup = DispatchGroup()
		let progress = Progress(totalUnitCount: 6)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		let observer = NCManagedObjectObserver() { [weak self] (updated, deleted) in
			if case let .success(_, record)? = self?.character,
				let object = record,
				updated?.contains(object) == true,
				let value = self?.character?.value {
				self?.reloadCharacterDetails(dataManager: dataManager, character: value, completionHandler: nil)
			}
			self?.update()
		}
		self.observer = observer
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.character { result in
				self.character = result
				
				progress.perform {
					switch result {
					case let .success(value, record):
						if let record = record {
							observer.add(managedObject: record)
						}
						dispatchGroup.enter()
						self.reloadCharacterDetails(dataManager: dataManager, character: value) {
							dispatchGroup.leave()
						}
					case .failure:
						break
					}
				}
				dispatchGroup.leave()
				self.update()
			}
		}
		
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.clones { result in
				self.clones = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
				self.update()
			}
		}

		progress.perform {
			dispatchGroup.enter()
			dataManager.skills { result in
				self.skills = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
				self.update()
			}
		}
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.wallets { result in
				self.wallets = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
				self.update()
			}
		}

		progress.perform {
			dispatchGroup.enter()
			dataManager.image(characterID: account.characterID, dimension: 512) { result in
				self.characterImage = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
				self.update()
			}
		}
		
		dispatchGroup.notify(queue: .main) {
			completionHandler?()
		}
	}
	
	
	private func reloadCharacterDetails(dataManager: NCDataManager, character: ESI.Character.Information, completionHandler: (() -> Void)?) {
		let progress = Progress(totalUnitCount: 3)
		
		let observer = NCManagedObjectObserver() { [weak self] (updated, deleted) in
			self?.update()
		}
		self.characterDetailsObserver = observer

		
		let dispatchGroup = DispatchGroup()
		
		progress.perform {
			dispatchGroup.enter()
			
			dataManager.corporation(corporationID: Int64(character.corporationID)) { result in
				self.corporation = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
				self.update()
			}
		}
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.image(corporationID: Int64(character.corporationID), dimension: 32) { result in
				self.corporationImage = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
				self.update()
			}
		}
		
		progress.perform {
			if let allianceID = character.allianceID, allianceID > 0 {
				dispatchGroup.enter()
				dataManager.image(allianceID: Int64(allianceID), dimension: 32) { result in
					self.allianceImage = result
					switch result {
					case let .success(_, record):
						if let record = record {
							observer.add(managedObject: record)
						}
					case .failure:
						break
					}
					dispatchGroup.leave()
					self.update()
				}
				
				dispatchGroup.enter()
				dataManager.alliance(allianceID: Int64(allianceID)) { result in
					self.alliance = result
					switch result {
					case let .success(_, record):
						if let record = record {
							observer.add(managedObject: record)
						}
					case .failure:
						break
					}
					dispatchGroup.leave()
					self.update()
				}
			}
		}
		
		dispatchGroup.notify(queue: .main) {
			completionHandler?()
		}
	}
	
	private func update() {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(reloadSections), object: nil)
		perform(#selector(reloadSections), with: nil, afterDelay: 0)
	}
	
	@objc private func reloadSections() {
		var sections = [TreeSection]()
		
		var rows = [TreeRow]()
		
		if let value = self.characterImage?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.image, nodeIdentifier: "CharacterImage", image: value))
		}
		if let value = self.corporation?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Corporation", image: self.corporationImage?.value, title: NSLocalizedString("Corporation", comment: "").uppercased(), subtitle: value.corporationName))
		}
		if let value = self.alliance?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Alliance", image: self.allianceImage?.value, title: NSLocalizedString("Alliance", comment: "").uppercased(), subtitle: value.allianceName))
		}
		
		if let value = self.clones?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "DoB", title: NSLocalizedString("Date of Birth", comment: "").uppercased(), subtitle: DateFormatter.localizedString(from: value.dateOfBirth, dateStyle: .short, timeStyle: .none)))
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Bloodline", title: NSLocalizedString("Bloodline", comment: "").uppercased(), subtitle: "\(value.race) / \(value.bloodLine) / \(value.ancestry)"))
		}
		if rows.count > 0 {
			sections.append(DefaultTreeSection(nodeIdentifier: "Bio", title: NSLocalizedString("Bio", comment: "").uppercased(), children: rows))
		}
		
		if let value = self.wallets?.value {
			var balance = 0.0
			value.forEach {balance += Double($0.balance ?? 0)}
			
			let row = DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Balance", title: NSLocalizedString("Balance", comment: "").uppercased(), subtitle: NCUnitFormatter.localizedString(from: balance / 100.0, unit: .isk, style: .full))
			sections.append(DefaultTreeSection(nodeIdentifier: "Account", title: NSLocalizedString("Account", comment: "").uppercased(), children: [row]))
		}
		
		rows = []
		
		if let value = self.skills?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
			                           nodeIdentifier: "SP",
			                           title: "\(value.skills?.count ?? 0) \(NSLocalizedString("skills", comment: ""))".uppercased(),
			                           subtitle: "\(NCUnitFormatter.localizedString(from: Double(value.totalSP ?? 0), unit: .skillPoints, style: .full))"))
		}
		if let value = self.clones?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Respecs", title: NSLocalizedString("Bonus Remaps Available", comment: "").uppercased(), subtitle: "\(value.freeRespecs)"))
			if let value = value.lastRespecDate {
				let calendar = Calendar(identifier: .gregorian)
				var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: value)
				components.year? += 1
				if let date = calendar.date(from: components) {
					let t = date.timeIntervalSinceNow
					let s: String
					
					if t <= 0 {
						s = NSLocalizedString("Now", comment: "")
					}
					else if t < 3600 * 24 * 7 {
						s = NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes)
					}
					else {
						s = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
					}

					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "RespecDate", title: NSLocalizedString("Neural Remap Available", comment: "").uppercased(), subtitle: s))
				}
			}
		}
		
		if rows.count > 0 {
			sections.append(DefaultTreeSection(nodeIdentifier: "Skills", title: NSLocalizedString("Skills", comment: "").uppercased(), children: rows))
		}
		
		if let value = self.clones?.value {
			rows = []
			let attributes = NCCharacterAttributes(clones: value)
			
			sections.append(NCCharacterAttributesSection(attributes: attributes, nodeIdentifier: "Attributes", title: NSLocalizedString("Attributes", comment: "").uppercased()))
			
			if let value = value.implants {
				rows = []
				let invTypes = NCDatabase.sharedDatabase?.invTypes

				let list = [(NCDBAttributeID.intelligenceBonus, NSLocalizedString("Intelligence", comment: "")),
				            (NCDBAttributeID.memoryBonus, NSLocalizedString("Memory", comment: "")),
				            (NCDBAttributeID.perceptionBonus, NSLocalizedString("Perception", comment: "")),
				            (NCDBAttributeID.willpowerBonus, NSLocalizedString("Willpower", comment: "")),
				            (NCDBAttributeID.charismaBonus, NSLocalizedString("Charisma", comment: ""))]

				
				let implants = value.flatMap { implant -> (NCDBInvType, Int)? in
					guard let type = invTypes?[implant.typeID] else {return nil}
					return (type, Int(type.allAttributes[NCDBAttributeID.implantness.rawValue]?.value ?? 100))
					}.sorted {$0.1 < $1.1}
				
				rows = implants.map { (type, _) -> TreeRow in
					if let enhancer = list.first(where: { (type.allAttributes[$0.0.rawValue]?.value ?? 0) > 0 }) {
						return DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                      nodeIdentifier: "\(type.typeID)Enhancer",
							image: type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image,
							title: type.typeName?.uppercased(),
							subtitle: "\(enhancer.1) +\(Int(type.allAttributes[enhancer.0.rawValue]!.value))",
							accessoryType: .disclosureIndicator,
							route: Router.Database.TypeInfo(type))
					}
					else {
						return DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
						                      nodeIdentifier: "\(type.typeID)Enhancer",
							image: type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image,
							title: type.typeName?.uppercased(),
							accessoryType: .disclosureIndicator,
							route: Router.Database.TypeInfo(type))
					}
				}
				
				if rows.isEmpty {
					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, nodeIdentifier: "NoImplants", title: NSLocalizedString("No Implants Installed", comment: "").uppercased()))
				}
				sections.append(DefaultTreeSection(nodeIdentifier: "Implants", title: NSLocalizedString("Implants", comment: "").uppercased(), children: rows))
			}
		}
		
		if treeController.content == nil {
			let root = TreeNode()
			root.children = sections
			treeController.content = root
		}
		else {
			treeController.content?.children = sections
		}

	}

	
}
