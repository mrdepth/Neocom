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

class NCCharacterSheetViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		needsReloadOnAccountChange = true
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.attribute,
		                    Prototype.NCDefaultTableViewCell.attributeNoImage,
		                    Prototype.NCDefaultTableViewCell.placeholder])
	}
	
	//MARK: - NCRefreshable
	
	private var character: NCCachedResult<ESI.Character.Information>?
	private var corporation: NCCachedResult<ESI.Corporation.Information>?
	private var alliance: NCCachedResult<ESI.Alliance.Information>?
	private var clones: NCCachedResult<EVE.Char.Clones>?
	private var skills: NCCachedResult<ESI.Skills.CharacterSkills>?
	private var skillQueue: NCCachedResult<[ESI.Skills.SkillQueueItem]>?
	private var wallets: NCCachedResult<[ESI.Wallet.Balance]>?
	private var characterImage: NCCachedResult<UIImage>?
	private var corporationImage: NCCachedResult<UIImage>?
	private var allianceImage: NCCachedResult<UIImage>?
	private var characterShip: NCCachedResult<ESI.Location.CharacterShip>?
	private var characterLocation: NCCachedResult<ESI.Location.CharacterLocation>?
	
	private var characterObserver: NCManagedObjectObserver?
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		guard let account = NCAccount.current else {
			completionHandler([])
			return
		}
		title = account.characterName
		
		let dispatchGroup = DispatchGroup()
		let progress = Progress(totalUnitCount: 9)
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.character { result in
				self.character = result
				
				if let cacheRecord = result.cacheRecord {
					self.characterObserver = NCManagedObjectObserver(managedObject: cacheRecord) { [weak self] _ in
						self?.reloadCharacterDetails(completionHandler: nil)
					}
				}
				
				progress.perform {
					self.reloadCharacterDetails {
						dispatchGroup.leave()
					}
				}
				self.update()
			}
		}
		
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.clones { result in
				self.clones = result
				dispatchGroup.leave()
				self.update()
			}
		}

		progress.perform {
			dispatchGroup.enter()
			dataManager.skills { result in
				self.skills = result
				dispatchGroup.leave()
				self.update()
			}
		}

		progress.perform {
			dispatchGroup.enter()
			dataManager.skillQueue { result in
				self.skillQueue = result
				dispatchGroup.leave()
				self.update()
			}
		}
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.wallets { result in
				self.wallets = result
				dispatchGroup.leave()
				self.update()
			}
		}

		progress.perform {
			dispatchGroup.enter()
			dataManager.image(characterID: account.characterID, dimension: 512) { result in
				self.characterImage = result
				dispatchGroup.leave()
				self.update()
			}
		}
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.characterLocation { result in
				self.characterLocation = result
				dispatchGroup.leave()
				self.update()
			}
		}

		progress.perform {
			dispatchGroup.enter()
			dataManager.characterShip { result in
				self.characterShip = result
				dispatchGroup.leave()
				self.update()
			}
		}

		
		dispatchGroup.notify(queue: .main) {
			
			let records = [self.character?.cacheRecord,
			               self.corporation?.cacheRecord,
			               self.alliance?.cacheRecord,
			               self.clones?.cacheRecord,
			               self.skills?.cacheRecord,
			               self.skillQueue?.cacheRecord,
			               self.wallets?.cacheRecord,
			               self.characterImage?.cacheRecord,
			               self.corporationImage?.cacheRecord,
			               self.allianceImage?.cacheRecord,
			               self.characterShip?.cacheRecord,
			               self.characterLocation?.cacheRecord].flatMap {$0}
			
			completionHandler(records)
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		
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
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, nodeIdentifier: "DoB", title: NSLocalizedString("Date of Birth", comment: "").uppercased(), subtitle: DateFormatter.localizedString(from: value.dateOfBirth, dateStyle: .short, timeStyle: .none)))
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, nodeIdentifier: "Bloodline", title: NSLocalizedString("Bloodline", comment: "").uppercased(), subtitle: "\(value.race) / \(value.bloodLine) / \(value.ancestry)"))
		}
		
		if let ship = self.characterShip?.value, let location = self.characterLocation?.value {
			if let type = NCDatabase.sharedDatabase?.invTypes[ship.shipTypeID], let solarSystem = NCDatabase.sharedDatabase?.mapSolarSystems[location.solarSystemID] {
				let location = NCLocation(solarSystem)
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Ship", image: type.icon?.image?.image, title: type.typeName?.uppercased(), attributedSubtitle: location.displayName, accessoryType: .disclosureIndicator,route: Router.Database.TypeInfo(type)))
			}
		}
		
		if rows.count > 0 {
			sections.append(DefaultTreeSection(nodeIdentifier: "Bio", title: NSLocalizedString("Bio", comment: "").uppercased(), children: rows))
		}
		
		if let value = self.wallets?.value {
			var balance = 0.0
			value.forEach {balance += Double($0.balance ?? 0)}
			
			let row = DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, nodeIdentifier: "Balance", title: NSLocalizedString("Balance", comment: "").uppercased(), subtitle: NCUnitFormatter.localizedString(from: balance / 100.0, unit: .isk, style: .full))
			sections.append(DefaultTreeSection(nodeIdentifier: "Account", title: NSLocalizedString("Account", comment: "").uppercased(), children: [row]))
		}
		
		rows = []
		
		if let clones = self.clones?.value, let skills = self.skills?.value, let skillQueue = self.skillQueue?.value {
			let character = NCCharacter(attributes: NCCharacterAttributes(clones: clones), skills: skills, skillQueue: skillQueue)
			let sp = character.skills.map{$0.value.skillPoints}.reduce(0, +)
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
			                           nodeIdentifier: "SP",
			                           title: "\(skills.skills?.count ?? 0) \(NSLocalizedString("skills", comment: ""))".uppercased(),
			                           subtitle: "\(NCUnitFormatter.localizedString(from: Double(sp), unit: .skillPoints, style: .full))"))
		}
		
		if let value = self.clones?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, nodeIdentifier: "Respecs", title: NSLocalizedString("Bonus Remaps Available", comment: "").uppercased(), subtitle: "\(value.freeRespecs)"))
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
					
					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, nodeIdentifier: "RespecDate", title: NSLocalizedString("Neural Remap Available", comment: "").uppercased(), subtitle: s))
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
		
		if treeController?.content == nil {
			treeController?.content = RootNode(sections)
		}
		else {
			treeController?.content?.children = sections
		}
		completionHandler()
	}
	
	private func reloadCharacterDetails(completionHandler: (() -> Void)?) {
		guard let character = self.character?.value else {
			completionHandler?()
			return
		}
		
		let progress = Progress(totalUnitCount: 3)
		
		let dispatchGroup = DispatchGroup()
		
		progress.perform {
			dispatchGroup.enter()
			
			dataManager.corporation(corporationID: Int64(character.corporationID)) { result in
				self.corporation = result
				dispatchGroup.leave()
				self.update()
			}
		}
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.image(corporationID: Int64(character.corporationID), dimension: 32) { result in
				self.corporationImage = result
				dispatchGroup.leave()
				self.update()
			}
		}
		
		progress.perform {
			if let allianceID = character.allianceID, allianceID > 0 {
				dispatchGroup.enter()
				dataManager.image(allianceID: Int64(allianceID), dimension: 32) { result in
					self.allianceImage = result
					dispatchGroup.leave()
					self.update()
				}
				
				dispatchGroup.enter()
				dataManager.alliance(allianceID: Int64(allianceID)) { result in
					self.alliance = result
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
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(internalUpdate), object: nil)
		perform(#selector(internalUpdate), with: nil, afterDelay: 0)
	}
	
	@objc private func internalUpdate() {
		updateContent {
		}
	}

	
}
