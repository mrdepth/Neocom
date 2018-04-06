//
//  NCAccountTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCAccountTableViewCell: NCTableViewCell {
	@IBOutlet weak var characterNameLabel: UILabel?
	@IBOutlet weak var characterImageView: UIImageView?
	@IBOutlet weak var corporationLabel: UILabel?
	@IBOutlet weak var spLabel: UILabel?
	@IBOutlet weak var wealthLabel: UILabel?
	@IBOutlet weak var locationLabel: UILabel?
//	@IBOutlet weak var subscriptionLabel: UILabel!
	@IBOutlet weak var skillLabel: UILabel?
	@IBOutlet weak var trainingTimeLabel: UILabel?
	@IBOutlet weak var skillQueueLabel: UILabel?
	@IBOutlet weak var trainingProgressView: UIProgressView?
	@IBOutlet weak var alertLabel: UILabel?
	
	var progressHandler: NCProgressHandler?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		let layer = self.trainingProgressView?.superview?.layer;
		layer?.borderColor = UIColor(number: 0x3d5866ff).cgColor
		layer?.borderWidth = 1.0 / UIScreen.main.scale
	}
}

extension Prototype {
	enum NCAccountTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCAccountTableViewCell", bundle: nil), reuseIdentifier: "NCAccountTableViewCell")
	}
}




class NCAccountsNode<Row: NCAccountRow>: TreeNode {
	let cachePolicy: URLRequest.CachePolicy
	
	init(context: NSManagedObjectContext, cachePolicy: URLRequest.CachePolicy) {
		self.cachePolicy = cachePolicy
		super.init()
		
		let defaultAccounts: FetchedResultsNode<NCAccount> = {
			let request = NSFetchRequest<NCAccount>(entityName: "Account")
			request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true),
									   NSSortDescriptor(key: "characterName", ascending: true)]
			request.predicate = NSPredicate(format: "folder == nil", "")
			
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
			return FetchedResultsNode(resultsController: results, objectNode: Row.self)
		}()
		
		let folders: FetchedResultsNode<NCAccountsFolder> = {
			let request = NSFetchRequest<NCAccountsFolder>(entityName: "AccountsFolder")
			request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
			
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
			return FetchedResultsNode(resultsController: results, objectNode: NCAccountsFolderSection<Row>.self)
		}()
		
		children = [DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.default, nodeIdentifier: "Default", title: NSLocalizedString("Default", comment: "").uppercased(), children: [defaultAccounts]), folders]
		
		
	}
}

class NCAccountsFolderSection<Row: NCAccountRow>: NCFetchedResultsObjectNode<NCAccountsFolder>, CollapseSerializable {
	var collapseState: NCCacheSectionCollapse?
	var collapseIdentifier: String? {
		return self.object.objectID.uriRepresentation().absoluteString
	}
	
	required init(object: NCAccountsFolder) {
		super.init(object: object)
		isExpandable = true
		cellIdentifier = Prototype.NCHeaderTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.titleLabel?.text = (object.name?.isEmpty == false ? object.name : NSLocalizedString("Unnamed", comment: ""))?.uppercased()
	}
	
	override func loadChildren() {
		guard let context = object.managedObjectContext else {return}
		let request = NSFetchRequest<NCAccount>(entityName: "Account")
		request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true),
								   NSSortDescriptor(key: "characterName", ascending: true)]
		request.predicate = NSPredicate(format: "folder == %@", object)
		
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		children = [FetchedResultsNode(resultsController: results, objectNode: Row.self)]
	}
	
	override func willMoveToTreeController(_ treeController: TreeController?) {
		if let collapseState = getCollapseState() {
			isExpanded = collapseState.isExpanded
			self.collapseState = collapseState
		}
		else {
			self.collapseState = nil
		}
		super.willMoveToTreeController(treeController)
	}
	
	override var isExpanded: Bool {
		didSet {
			collapseState?.isExpanded = isExpanded
		}
	}
}

class NCAccountRow: NCFetchedResultsObjectNode<NCAccount> {
	
	private struct LoadingOptions: OptionSet {
		var rawValue: Int
		static let characterInfo = LoadingOptions(rawValue: 1 << 0)
		static let corporationInfo = LoadingOptions(rawValue: 1 << 1)
		static let skillQueue = LoadingOptions(rawValue: 1 << 2)
		static let skills = LoadingOptions(rawValue: 1 << 3)
		static let walletBalance = LoadingOptions(rawValue: 1 << 4)
		static let characterLocation = LoadingOptions(rawValue: 1 << 5)
		static let characterShip = LoadingOptions(rawValue: 1 << 6)
		static let image = LoadingOptions(rawValue: 1 << 7)
		var count: Int {
			return sequence(first: rawValue) {$0 > 1 ? $0 >> 1 : nil}.reduce(0) {
				$0 + (($1 & 1) == 1 ? 1 : 0)
			}
		}
	}

	required init(object: NCAccount) {
		super.init(object: object)
		canMove = true
		cellIdentifier = Prototype.NCAccountTableViewCell.default.reuseIdentifier
	}
	
	var cachePolicy: URLRequest.CachePolicy {
		var parent = self.parent
		while parent != nil && !(parent is NCAccountsNode) {
			parent = parent?.parent
		}
		return (parent as? NCAccountsNode)?.cachePolicy ?? .useProtocolCachePolicy
	}
	
	lazy var dataManager: NCDataManager = {
		return NCDataManager(account: self.object, cachePolicy: self.cachePolicy)
	}()
	
	var character: NCCachedResult<ESI.Character.Information>?
	var corporation: NCCachedResult<ESI.Corporation.Information>?
	var skillQueue: NCCachedResult<[ESI.Skills.SkillQueueItem]>?
	var walletBalance: NCCachedResult<Double>?
	var skills: NCCachedResult<ESI.Skills.CharacterSkills>?
	var location: NCCachedResult<ESI.Location.CharacterLocation>?
	var ship: NCCachedResult<ESI.Location.CharacterShip>?
	var image: NCCachedResult<UIImage>?
	
	var isLoaded = false
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCAccountTableViewCell else {return}
		
		
		cell.object = object
		if !isLoaded {
			var options = LoadingOptions()
			if cell.corporationLabel != nil {
				options.insert(.characterInfo)
				options.insert(.corporationInfo)
			}
			if cell.skillQueueLabel != nil {
				options.insert(.skillQueue)
			}
			if cell.skillLabel != nil {
				options.insert(.skills)
			}
			if cell.wealthLabel != nil {
				options.insert(.walletBalance)
			}
			if cell.locationLabel != nil{
				options.insert(.characterLocation)
				options.insert(.characterShip)
			}
			if cell.imageView != nil {
				options.insert(.image)
			}
			reload(options: options)
			isLoaded = true
		}
		
		configureImage(cell: cell)
		configureSkills(cell: cell)
		configureWallets(cell: cell)
		configureLocation(cell: cell)
		configureCharacter(cell: cell)
		configureSkillQueue(cell: cell)
		configureCorporation(cell: cell)
		
		if object.isInvalid {
			cell.alertLabel?.isHidden = true
		}
		else {
			if let scopes = object.scopes?.compactMap({($0 as? NCScope)?.name}), Set(ESI.Scope.default.map{$0.rawValue}).isSubset(of: Set(scopes)) {
				cell.alertLabel?.isHidden = true
			}
			else {
				cell.alertLabel?.isHidden = false
			}
		}
	}
	
	func configureCharacter(cell: NCAccountTableViewCell) {
		if object.isInvalid {
			cell.characterNameLabel?.text = object.characterName
		}
		else {
			if let value = character?.value {
				cell.characterNameLabel?.text = value.name
			}
			else {
				cell.characterNameLabel?.text = character?.error?.localizedDescription ?? object.characterName ?? " "
			}
		}
	}
	
	func configureCorporation(cell: NCAccountTableViewCell) {
		if object.isInvalid {
			cell.corporationLabel?.text = NSLocalizedString("Access Token did become invalid", comment: "")
			cell.corporationLabel?.textColor = .red
		}
		else {
			cell.corporationLabel?.textColor = .white
			if let value = corporation?.value {
				cell.corporationLabel?.text = value.name
			}
			else {
				cell.corporationLabel?.text = corporation?.error?.localizedDescription ?? " "
			}
		}
	}
	
	func configureSkillQueue(cell: NCAccountTableViewCell) {
		if object.isInvalid {
			cell.skillLabel?.text = " "
			cell.skillQueueLabel?.text = " "
			cell.trainingTimeLabel?.text = " "
			cell.trainingProgressView?.progress = 0
			
		}
		else {
			if let value = skillQueue?.value {
				let date = Date()
				
				let skillQueue = value.filter {
					guard let finishDate = $0.finishDate else {return false}
					return finishDate >= date
				}
				
				let firstSkill = skillQueue.first { $0.finishDate! > date }
				
				let trainingTime: String
				let trainingProgress: Float
				let title: NSAttributedString
				
				if let skill = firstSkill {
					guard let type = NCDatabase.sharedDatabase?.invTypes[skill.skillID] else {return}
					guard let firstTrainingSkill = NCSkill(type: type, skill: skill) else {return}
					
					if !firstTrainingSkill.typeName.isEmpty {
						title = NSAttributedString(skillName: firstTrainingSkill.typeName, level: 1 + (firstTrainingSkill.level ?? 0))
					}
					else {
						title = NSAttributedString(string: String(format: NSLocalizedString("Unknown skill %d", comment: ""), firstTrainingSkill.typeID))
					}
					
					trainingProgress = firstTrainingSkill.trainingProgress
					if let endTime = firstTrainingSkill.trainingEndDate {
						trainingTime = NCTimeIntervalFormatter.localizedString(from: endTime.timeIntervalSinceNow, precision: .minutes)
					}
					else {
						trainingTime = " "
					}
				}
				else {
					title = NSAttributedString(string: NSLocalizedString("No skills in training", comment: ""), attributes: [NSAttributedStringKey.foregroundColor: UIColor.lightText])
					trainingProgress = 0
					trainingTime = " "
				}
				
				let skillQueueText: String
				
				if let skill = skillQueue.last, let endTime = skill.finishDate {
					skillQueueText = String(format: NSLocalizedString("%d skills in queue (%@)", comment: ""), skillQueue.count, NCTimeIntervalFormatter.localizedString(from: endTime.timeIntervalSinceNow, precision: .minutes))
				}
				else {
					skillQueueText = " "
				}
				
				
				cell.skillLabel?.attributedText = title
				cell.trainingTimeLabel?.text = trainingTime
				cell.trainingProgressView?.progress = trainingProgress
				cell.skillQueueLabel?.text = skillQueueText
			}
			else {
				cell.skillLabel?.text = skillQueue?.error?.localizedDescription ?? " "
				cell.skillQueueLabel?.text = " "
				cell.trainingTimeLabel?.text = " "
				cell.trainingProgressView?.progress = 0
			}
		}
	}
	
	func configureWallets(cell: NCAccountTableViewCell) {
		if object.isInvalid {
			cell.wealthLabel?.text = " "
		}
		else {
			if let value = walletBalance?.value {
				let wealth = Double(value)
				cell.wealthLabel?.text = NCUnitFormatter.localizedString(from: wealth, unit: .none, style: .short)
			}
			else {
				cell.wealthLabel?.text = walletBalance?.error?.localizedDescription ?? " "
			}
		}
	}
	
	func configureSkills(cell: NCAccountTableViewCell) {
		if object.isInvalid {
			cell.spLabel?.text = " "
		}
		else {
			if let value = skills?.value {
				cell.spLabel?.text = NCUnitFormatter.localizedString(from: Double(value.totalSP), unit: .none, style: .short)
			}
			else {
				cell.spLabel?.text = skills?.error?.localizedDescription ?? " "
			}
		}
	}
	
	func configureLocation(cell: NCAccountTableViewCell) {
		if object.isInvalid {
			cell.locationLabel?.text = " "
		}
		else {
			
			let location: String? = {
				guard let value = self.location?.value, let solarSystem = NCDatabase.sharedDatabase?.mapSolarSystems[value.solarSystemID] else {return nil}
				return "\(solarSystem.solarSystemName!) / \(solarSystem.constellation!.region!.regionName!)"
			}()
			
			let ship: String? = {
				guard let value = self.ship?.value, let type = NCDatabase.sharedDatabase?.invTypes[value.shipTypeID] else {return nil}
				return type.typeName
			}()
			
			if let ship = ship, let location = location {
				let s = NSMutableAttributedString()
				s.append(NSAttributedString(string: ship, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white]))
				s.append(NSAttributedString(string: ", \(location)", attributes: [NSAttributedStringKey.foregroundColor: UIColor.lightText]))
				cell.locationLabel?.attributedText = s
			}
			else if let location = location {
				let s = NSAttributedString(string: location, attributes: [NSAttributedStringKey.foregroundColor: UIColor.lightText])
				cell.locationLabel?.attributedText = s
			}
			else if let ship = ship {
				let s = NSAttributedString(string: ship, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
				cell.locationLabel?.attributedText = s
			}
			else {
				cell.locationLabel?.text = self.location?.error?.localizedDescription ?? self.ship?.error?.localizedDescription ?? " "
			}
		}
	}
	
	
	func configureImage(cell: NCAccountTableViewCell) {
		if let value = image?.value {
			cell.characterImageView?.image = value
		}
		else {
			cell.characterImageView?.image = UIImage()
		}
	}
	
	private var observer: NCManagedObjectObserver?
	private var isLoading: Bool = false
	
	private func reload(options: LoadingOptions, completionHandler: (()->Void)? = nil) {
		guard !isLoading else {
			completionHandler?()
			return
		}
		
		isLoading = true
		
		if object.isInvalid {
			dataManager.image(characterID: object.characterID, dimension: 64) { result in
				self.image = result
				
				if let record = result.cacheRecord {
					self.observer?.add(managedObject: record)
				}
				
				if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
					self.configureImage(cell: cell)
				}
				self.isLoading = false
				completionHandler?()
			}
		}
		else {
			
			observer = NCManagedObjectObserver() { [weak self] (updated, deleted) in
				guard let strongSelf = self else {return}
				guard let cell = strongSelf.treeController?.cell(for: strongSelf) as? NCAccountTableViewCell else {return}
				
				if case let .success(_, record)? = strongSelf.character, updated?.contains(record!) == true {
					strongSelf.configureCharacter(cell: cell)
				}
				if case let .success(_, record)? = strongSelf.corporation, updated?.contains(record!) == true {
					strongSelf.configureCorporation(cell: cell)
				}
				if case let .success(_, record)? = strongSelf.skillQueue, updated?.contains(record!) == true {
					strongSelf.configureSkillQueue(cell: cell)
				}
				if case let .success(_, record)? = strongSelf.walletBalance, updated?.contains(record!) == true {
					strongSelf.configureWallets(cell: cell)
				}
				if case let .success(_, record)? = strongSelf.skills, updated?.contains(record!) == true {
					strongSelf.configureSkills(cell: cell)
				}
				if case let .success(_, record)? = strongSelf.location, updated?.contains(record!) == true {
					strongSelf.configureLocation(cell: cell)
				}
				else if case let .success(_, record)? = strongSelf.ship, updated?.contains(record!) == true {
					strongSelf.configureLocation(cell: cell)
				}
				if case let .success(_, record)? = strongSelf.image, updated?.contains(record!) == true {
					strongSelf.configureImage(cell: cell)
				}
			}
			
			let dataManager = self.dataManager
			
			let cell = treeController?.cell(for: self)
			let progress = cell != nil ? NCProgressHandler(view: cell!, totalUnitCount: Int64(options.count)) : nil
			let dispatchGroup = DispatchGroup()
			
			if options.contains(.characterInfo) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				dispatchGroup.enter()
				dataManager.character { result in
					self.character = result
					
					switch result {
					case let .success(value, record):
						if let record = record {
							self.observer?.add(managedObject: record)
						}
						
						if options.contains(.corporationInfo) {
							progress?.progress.becomeCurrent(withPendingUnitCount: 1)
							dispatchGroup.enter()
							dataManager.corporation(corporationID: Int64(value.corporationID)) { result in
								self.corporation = result
								dispatchGroup.leave()
								
								if let record = result.cacheRecord {
									self.observer?.add(managedObject: record)
								}
								
								
								if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
									self.configureCorporation(cell: cell)
								}
								
							}
							progress?.progress.resignCurrent()
						}
					case .failure:
						break
					}
					
					dispatchGroup.leave()
					
					if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
						self.configureCharacter(cell: cell)
					}
				}
				progress?.progress.resignCurrent()
			}
			
			if options.contains(.skillQueue) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				dispatchGroup.enter()
				dataManager.skillQueue { result in
					self.skillQueue = result
					dispatchGroup.leave()
					
					if let record = result.cacheRecord {
						self.observer?.add(managedObject: record)
					}
					
					if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
						self.configureSkillQueue(cell: cell)
					}
				}
				progress?.progress.resignCurrent()
			}
			
			if options.contains(.skills) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				dispatchGroup.enter()
				dataManager.skills { result in
					self.skills = result
					dispatchGroup.leave()
					
					if let record = result.cacheRecord {
						self.observer?.add(managedObject: record)
					}
					
					if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
						self.configureSkills(cell: cell)
					}
				}
				progress?.progress.resignCurrent()
			}
			
			if options.contains(.walletBalance) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				dispatchGroup.enter()
				dataManager.walletBalance { result in
					self.walletBalance = result
					dispatchGroup.leave()
					
					if let record = result.cacheRecord {
						self.observer?.add(managedObject: record)
					}
					
					if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
						self.configureWallets(cell: cell)
					}
				}
				progress?.progress.resignCurrent()
			}
			
			if options.contains(.characterLocation) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				dispatchGroup.enter()
				dataManager.characterLocation { result in
					self.location = result
					dispatchGroup.leave()
					
					if let record = result.cacheRecord {
						self.observer?.add(managedObject: record)
					}
					
					if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
						self.configureLocation(cell: cell)
					}
				}
				progress?.progress.resignCurrent()
			}
			
			if options.contains(.characterShip) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				dispatchGroup.enter()
				dataManager.characterShip { result in
					self.ship = result
					dispatchGroup.leave()
					
					if let record = result.cacheRecord {
						self.observer?.add(managedObject: record)
					}
					
					if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
						self.configureLocation(cell: cell)
					}
				}
				progress?.progress.resignCurrent()
			}
			
			
			if options.contains(.image) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				dispatchGroup.enter()
				dataManager.image(characterID: object.characterID, dimension: 64) { result in
					self.image = result
					dispatchGroup.leave()
					
					if let record = result.cacheRecord {
						self.observer?.add(managedObject: record)
					}
					
					if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
						self.configureImage(cell: cell)
					}
				}
				progress?.progress.resignCurrent()
			}
			
			dispatchGroup.notify(queue: .main) {
				progress?.finish()
				self.isLoading = false
				completionHandler?()
			}
		}
	}
	
}


