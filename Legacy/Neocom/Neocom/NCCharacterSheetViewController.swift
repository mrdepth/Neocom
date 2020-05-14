//
//  NCCharacterSheetViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import Futures

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
		accountChangeAction = .reload
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.attribute,
		                    Prototype.NCDefaultTableViewCell.attributeNoImage,
		                    Prototype.NCDefaultTableViewCell.placeholder])
	}
	
	//MARK: - NCRefreshable
	
	private var character: CachedValue<ESI.Character.Information>?
	private var corporation: CachedValue<ESI.Corporation.Information>?
	private var alliance: CachedValue<ESI.Alliance.Information>?
	private var clones: CachedValue<ESI.Clones.JumpClones>?
	private var attributes: CachedValue<ESI.Skills.CharacterAttributes>?
	private var implants: CachedValue<[Int]>?
	private var skills: CachedValue<ESI.Skills.CharacterSkills>?
	private var skillQueue: CachedValue<[ESI.Skills.SkillQueueItem]>?
	private var walletBalance: CachedValue<Double>?
	private var characterImage: CachedValue<UIImage>?
	private var corporationImage: CachedValue<UIImage>?
	private var allianceImage: CachedValue<UIImage>?
	private var characterShip: CachedValue<ESI.Location.CharacterShip>?
	private var characterLocation: CachedValue<ESI.Location.CharacterLocation>?
	
	private var characterObserver: NCManagedObjectObserver?
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		guard let account = NCAccount.current else {
			return .init([])
		}
		title = account.characterName
		
		let progress = Progress(totalUnitCount: 11)
		let dataManager = self.dataManager
		
		let characterID = account.characterID
		
		return DispatchQueue.global(qos: .utility).async { () -> [NCCacheRecord] in
			let character = progress.perform{dataManager.character()}

			let characterDetails = character.then(on: .main) { result -> Future<[NCCacheRecord]> in
				self.character = result
				DispatchQueue.main.async {
					self.characterObserver = NCManagedObjectObserver(managedObject: result.cacheRecord(in: NCCache.sharedCache!.viewContext)) { [weak self] (_,_) in
						_ = self?.loadCharacterDetails()
					}
				}
				self.update()
				return progress.perform{self.loadCharacterDetails()}
			}

			let clones = progress.perform{dataManager.clones()}.then(on: .main) { result -> CachedValue<ESI.Clones.JumpClones> in
				self.clones = result
				self.update()
				return result
			}

			let attributes = progress.perform{dataManager.attributes()}.then(on: .main) { result -> CachedValue<ESI.Skills.CharacterAttributes> in
				self.attributes = result
				self.update()
				return result
			}

			
			let implants = progress.perform{dataManager.implants()}.then(on: .main) { result -> CachedValue<[Int]> in
				self.implants = result
				self.update()
				return result
			}

			let skills = progress.perform{dataManager.skills()}.then(on: .main) { result -> CachedValue<ESI.Skills.CharacterSkills> in
				self.skills = result
				self.update()
				return result
			}

			let skillQueue = progress.perform{dataManager.skillQueue()}.then(on: .main) { result -> CachedValue<[ESI.Skills.SkillQueueItem]> in
				self.skillQueue = result
				self.update()
				return result
			}

			let walletBalance = progress.perform{dataManager.walletBalance()}.then(on: .main) { result -> CachedValue<Double> in
				self.walletBalance = result
				self.update()
				return result
			}

			let characterImage = progress.perform{dataManager.image(characterID: characterID, dimension: 512)}.then(on: .main) { result -> CachedValue<UIImage> in
				self.characterImage = result
				self.update()
				return result
			}

			let characterLocation = progress.perform{dataManager.characterLocation()}.then(on: .main) { result -> CachedValue<ESI.Location.CharacterLocation> in
				self.characterLocation = result
				self.update()
				return result
			}

			let characterShip = progress.perform{dataManager.characterShip()}.then(on: .main) { result -> CachedValue<ESI.Location.CharacterShip> in
				self.characterShip = result
				self.update()
				return result
			}

			var records = [character.then(on: .main) {$0.cacheRecord(in: NCCache.sharedCache!.viewContext)},
						   clones.then(on: .main) {$0.cacheRecord(in: NCCache.sharedCache!.viewContext)},
						   attributes.then(on: .main) {$0.cacheRecord(in: NCCache.sharedCache!.viewContext)},
						   implants.then(on: .main) {$0.cacheRecord(in: NCCache.sharedCache!.viewContext)},
						   skills.then(on: .main) {$0.cacheRecord(in: NCCache.sharedCache!.viewContext)},
						   skillQueue.then(on: .main) {$0.cacheRecord(in: NCCache.sharedCache!.viewContext)},
						   walletBalance.then(on: .main) {$0.cacheRecord(in: NCCache.sharedCache!.viewContext)},
						   characterImage.then(on: .main) {$0.cacheRecord(in: NCCache.sharedCache!.viewContext)},
						   characterLocation.then(on: .main) {$0.cacheRecord(in: NCCache.sharedCache!.viewContext)},
						   characterShip.then(on: .main) {$0.cacheRecord(in: NCCache.sharedCache!.viewContext)}].compactMap { try? $0.get() }
			do {
				records.append(contentsOf: try characterDetails.get())
			}
			catch {}
			return records
			
		}
	}
	
	override func content() -> Future<TreeNode?> {
		var sections = [TreeSection]()
		
		var rows = [TreeRow]()
		
		if let value = self.characterImage?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.image, nodeIdentifier: "CharacterImage", image: value))
		}
		if let value = self.corporation?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Corporation", image: self.corporationImage?.value, title: NSLocalizedString("Corporation", comment: "").uppercased(), subtitle: value.name))
		}
		if let value = self.alliance?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Alliance", image: self.allianceImage?.value, title: NSLocalizedString("Alliance", comment: "").uppercased(), subtitle: value.name))
		}
		
		if let value = self.character?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, nodeIdentifier: "DoB", title: NSLocalizedString("Date of Birth", comment: "").uppercased(), subtitle: DateFormatter.localizedString(from: value.birthday, dateStyle: .short, timeStyle: .none)))
			if let race = NCDatabase.sharedDatabase?.chrRaces[value.raceID]?.raceName,
				let bloodline = NCDatabase.sharedDatabase?.chrBloodlines[value.bloodlineID]?.bloodlineName,
				let ancestryID = value.ancestryID,
				let ancestry = NCDatabase.sharedDatabase?.chrAncestries[ancestryID]?.ancestryName {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, nodeIdentifier: "Bloodline", title: NSLocalizedString("Bloodline", comment: "").uppercased(), subtitle: "\(race) / \(bloodline) / \(ancestry)"))
			}
			if let ss = value.securityStatus {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, nodeIdentifier: "SS", title: NSLocalizedString("Security Status", comment: "").uppercased(), attributedSubtitle: String(format: "%.1f", ss) * [NSAttributedStringKey.foregroundColor: UIColor(security: ss)]))
			}
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
		
		if let value = self.walletBalance?.value {
			let balance = Double(value)
			
			let row = DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, nodeIdentifier: "Balance", title: NSLocalizedString("Balance", comment: "").uppercased(), subtitle: NCUnitFormatter.localizedString(from: balance, unit: .isk, style: .full))
			sections.append(DefaultTreeSection(nodeIdentifier: "Account", title: NSLocalizedString("Account", comment: "").uppercased(), children: [row]))
		}
		
		rows = []
		
		if let attributes = self.attributes?.value, let implants = self.implants?.value, let skills = self.skills?.value, let skillQueue = self.skillQueue?.value {
			let character = NCCharacter(attributes: NCCharacterAttributes(attributes: attributes, implants: implants), skills: skills, skillQueue: skillQueue)
			let sp = character.skills.map{$0.value.skillPoints}.reduce(0, +)
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
			                           nodeIdentifier: "SP",
			                           title: "\(skills.skills.count) \(NSLocalizedString("skills", comment: ""))".uppercased(),
			                           subtitle: "\(NCUnitFormatter.localizedString(from: Double(sp), unit: .skillPoints, style: .full))"))
		}
		
		if let value = self.attributes?.value {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage, nodeIdentifier: "Respecs", title: NSLocalizedString("Bonus Remaps Available", comment: "").uppercased(), subtitle: "\(value.bonusRemaps ?? 0)"))
			if let value = value.lastRemapDate {
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
		
		if let attributes = self.attributes?.value, let implants = self.implants?.value {
			rows = []
			let attributes = NCCharacterAttributes(attributes: attributes, implants: implants)
			
			sections.append(NCCharacterAttributesSection(attributes: attributes, nodeIdentifier: "Attributes", title: NSLocalizedString("Attributes", comment: "").uppercased()))
			
			if !implants.isEmpty {
				rows = []
				let invTypes = NCDatabase.sharedDatabase?.invTypes
				
				let list = [(NCDBAttributeID.intelligenceBonus, NSLocalizedString("Intelligence", comment: "")),
				            (NCDBAttributeID.memoryBonus, NSLocalizedString("Memory", comment: "")),
				            (NCDBAttributeID.perceptionBonus, NSLocalizedString("Perception", comment: "")),
				            (NCDBAttributeID.willpowerBonus, NSLocalizedString("Willpower", comment: "")),
				            (NCDBAttributeID.charismaBonus, NSLocalizedString("Charisma", comment: ""))]
				
				
				let implants = implants.compactMap { implant -> (NCDBInvType, Int)? in
					guard let type = invTypes?[implant] else {return nil}
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
		
		guard !sections.isEmpty else { return .init(.failure(NCTreeViewControllerError.noResult)) }
		return .init(RootNode(sections, collapseIdentifier: "NCCharacterSheetViewController"))
	}
	
	private func loadCharacterDetails() -> Future<[NCCacheRecord]> {
		guard let character = self.character?.value else {
			return .init([])
		}
		
		let progress = Progress(totalUnitCount: 4)
		
		let dataManager = self.dataManager
		
		return DispatchQueue.global(qos: .utility).async { () -> Future<[NCCacheRecord]> in
			var futures = [Future<NCCacheRecord>]()
			
			let corporation = progress.perform{dataManager.corporation(corporationID: Int64(character.corporationID))}
			corporation.then(on: .main) { result in
				self.corporation = result
			}
			futures.append(corporation.then(on: .main){$0.cacheRecord(in: NCCache.sharedCache!.viewContext)})
			
			let corporationImage = progress.perform{dataManager.image(corporationID: Int64(character.corporationID), dimension: 32)}
			corporationImage.then(on: .main) { result in
				self.corporationImage = result
			}
			futures.append(corporationImage.then(on: .main){$0.cacheRecord(in: NCCache.sharedCache!.viewContext)})
			
			if let allianceID = (try? corporation.get())?.value?.allianceID {
				let alliance = progress.perform{dataManager.alliance(allianceID: Int64(allianceID))}
				alliance.then(on: .main) { result in
					self.alliance = result
				}
				futures.append(alliance.then(on: .main){$0.cacheRecord(in: NCCache.sharedCache!.viewContext)})
				
				let allianceImage = progress.perform{dataManager.image(allianceID: Int64(allianceID), dimension: 32)}
				allianceImage.then(on: .main) { result in
					self.allianceImage = result
				}
				futures.append(allianceImage.then(on: .main){$0.cacheRecord(in: NCCache.sharedCache!.viewContext)})
			}
			else {
				progress.completedUnitCount += 2
			}
			return all(futures).finally(on: .main) {
				self.update()
			}
		}
	}
	
	private func update() {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(internalUpdate), object: nil)
		perform(#selector(internalUpdate), with: nil, afterDelay: 0)
	}
	
	@objc private func internalUpdate() {
		updateContent()
	}

	
}
