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
	
	var character: Future<CachedValue<ESI.Character.Information>>?
	var corporation: Future<CachedValue<ESI.Corporation.Information>>?
	var skillQueue: Future<CachedValue<[ESI.Skills.SkillQueueItem]>>?
	var walletBalance: Future<CachedValue<Double>>?
	var skills: Future<CachedValue<ESI.Skills.CharacterSkills>>?
	var location: Future<CachedValue<ESI.Location.CharacterLocation>>?
	var ship: Future<CachedValue<ESI.Location.CharacterShip>>?
	var image: Future<CachedValue<UIImage>>?
	
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
			_ = reload(options: options)
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
			cell.characterNameLabel?.text = " "
			character?.then(on: .main) { result in
				guard cell.object as? NCAccount == self.object else {return}
				cell.characterNameLabel?.text = result.value?.name ?? " "
			}.catch(on: .main) { error in
				guard cell.object as? NCAccount == self.object else {return}
				cell.characterNameLabel?.text = error.localizedDescription
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
			cell.corporationLabel?.text = " "
			corporation?.then(on: .main) { result in
				guard cell.object as? NCAccount == self.object else {return}
				cell.corporationLabel?.text = result.value?.name ?? " "
			}.catch(on: .main) { error in
				guard cell.object as? NCAccount == self.object else {return}
				cell.corporationLabel?.text = error.localizedDescription
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
			cell.skillLabel?.text = " "
			cell.skillQueueLabel?.text = " "
			cell.trainingTimeLabel?.text = " "
			cell.trainingProgressView?.progress = 0

			skillQueue?.then(on: .main) { result in
				guard cell.object as? NCAccount == self.object else {return}
				guard let value = result.value else {return}
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
			}.catch(on: .main) { error in
				guard cell.object as? NCAccount == self.object else {return}
				cell.skillLabel?.text = error.localizedDescription
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
			cell.wealthLabel?.text = " "
			walletBalance?.then(on: .main) { result in
				guard cell.object as? NCAccount == self.object else {return}
				guard let wealth = result.value else {return}
				cell.wealthLabel?.text = NCUnitFormatter.localizedString(from: wealth, unit: .none, style: .short)
			}.catch(on: .main) { error in
				guard cell.object as? NCAccount == self.object else {return}
				cell.wealthLabel?.text = error.localizedDescription
			}
		}
	}
	
	func configureSkills(cell: NCAccountTableViewCell) {
		if object.isInvalid {
			cell.spLabel?.text = " "
		}
		else {
			cell.spLabel?.text = " "
			skills?.then(on: .main) { result in
				guard cell.object as? NCAccount == self.object else {return}
				guard let value = result.value else {return}
				cell.spLabel?.text = NCUnitFormatter.localizedString(from: Double(value.totalSP), unit: .none, style: .short)
			}.catch(on: .main) { error in
				guard cell.object as? NCAccount == self.object else {return}
				cell.spLabel?.text = error.localizedDescription
			}
		}
	}
	
	func configureLocation(cell: NCAccountTableViewCell) {
		if object.isInvalid {
			cell.locationLabel?.text = " "
		}
		else {
			all(
				self.location?.then(on: .main) { result -> String? in
					guard let value = result.value else {return nil}
					guard let solarSystem = NCDatabase.sharedDatabase?.mapSolarSystems[value.solarSystemID] else {return nil}
					return "\(solarSystem.solarSystemName!) / \(solarSystem.constellation!.region!.regionName!)"
				} ?? .init(nil),
				self.ship?.then(on: .main) { result -> String? in
					guard let value = result.value else {return nil}
					guard let type = NCDatabase.sharedDatabase?.invTypes[value.shipTypeID] else {return nil}
					return type.typeName
				} ?? .init(nil)
			).then(on: .main) { (location, ship) in
				guard cell.object as? NCAccount == self.object else {return}
				
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
					cell.locationLabel?.text = " "
				}
			}.catch(on: .main) { error in
				guard cell.object as? NCAccount == self.object else {return}
				cell.locationLabel?.text = error.localizedDescription
			}
		}
	}
	
	
	func configureImage(cell: NCAccountTableViewCell) {
		cell.characterImageView?.image = UIImage()
		image?.then(on: .main) { result in
			guard cell.object as? NCAccount == self.object else {return}
			cell.characterImageView?.image = result.value
		}
	}
	
	private var observer: NCManagedObjectObserver?
	private var isLoading: Bool = false
	
	private func reconfigure() {
//		guard let cell = self.treeController?.cell(for: self) else {return}
//		self.configure(cell: cell)
	}
	
	private func reload(options: LoadingOptions) -> Future<Void> {
		guard !isLoading else {
			return .init(())
		}
		
		isLoading = true
		if object.isInvalid {
			image = dataManager.image(characterID: object.characterID, dimension: 64)
			
			image?.then(on: .main) { result in
				self.reconfigure()
				self.isLoading = false
			}
			return .init(())
		}
		else {
			
			observer = NCManagedObjectObserver() { [weak self] (updated, deleted) in
				guard let strongSelf = self else {return}
				strongSelf.reconfigure()
			}
			
			let dataManager = self.dataManager

			let cell = treeController?.cell(for: self)
			let progress = cell != nil ? NCProgressHandler(view: cell!, totalUnitCount: Int64(options.count)) : nil
			
			var queue = [Future<Void>]()
			
			if options.contains(.characterInfo) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				character = dataManager.character()
				progress?.progress.resignCurrent()
				
				queue.append(
					character!.then(on: .main) { result -> Future<Void> in
						guard let value = result.value else {throw NCDataManagerError.noCacheData}
						self.observer?.add(managedObject: result.cacheRecord)
						self.reconfigure()
						
						if options.contains(.corporationInfo) {
							progress?.progress.becomeCurrent(withPendingUnitCount: 1)
							self.corporation = dataManager.corporation(corporationID: Int64(value.corporationID))
							progress?.progress.resignCurrent()
							
							return self.corporation!.then(on: .main) { result -> Void in
								self.observer?.add(managedObject: result.cacheRecord)
								self.reconfigure()
							}
						}
						else {
							return .init(())
						}
				})
			}
			
			if options.contains(.skillQueue) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				skillQueue = dataManager.skillQueue()
				progress?.progress.resignCurrent()
				
				queue.append(
					skillQueue!.then(on: .main) { result -> Void in
						self.observer?.add(managedObject: result.cacheRecord)
						self.reconfigure()
				})
				
			}
			
			if options.contains(.skills) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				skills = dataManager.skills()
				progress?.progress.resignCurrent()
				
				queue.append(
					skills!.then(on: .main) { result -> Void in
						self.observer?.add(managedObject: result.cacheRecord)
						self.reconfigure()
				})
			}
			
			if options.contains(.walletBalance) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				walletBalance = dataManager.walletBalance()
				progress?.progress.resignCurrent()

				queue.append(
					walletBalance!.then(on: .main) { result -> Void in
						self.observer?.add(managedObject: result.cacheRecord)
						self.reconfigure()
					}
				)
			}
			
			if options.contains(.characterLocation) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				location = dataManager.characterLocation()
				progress?.progress.resignCurrent()
				
				queue.append(
					location!.then(on: .main) { result -> Void in
						self.observer?.add(managedObject: result.cacheRecord)
						self.reconfigure()
				})
			}
			
			if options.contains(.characterShip) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				ship = dataManager.characterShip()
				progress?.progress.resignCurrent()
				
				queue.append(
					ship!.then(on: .main) { result -> Void in
						self.observer?.add(managedObject: result.cacheRecord)
						self.reconfigure()
				})
			}
			
			
			if options.contains(.image) {
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				image = dataManager.image(characterID: object.characterID, dimension: 64)
				progress?.progress.resignCurrent()
				
				queue.append(
					image!.then(on: .main) { result -> Void in
						self.observer?.add(managedObject: result.cacheRecord)
						self.reconfigure()
				})
			}
			
			return all(queue).then { _ -> Void in
				}.finally(on: .main) {
					progress?.finish()
					self.isLoading = false
					guard let cell = self.treeController?.cell(for: self) else {return}
					self.configure(cell: cell)
			}
		}
	}
	
}


