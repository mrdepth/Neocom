//
//  NCAccountsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCAccountInfo: NSObject {
	dynamic var characterName: String = " "
	dynamic var corporation: String = " "
	dynamic var alliance: String = " "
	dynamic var characterImage: UIImage?
	dynamic var corporationImage: UIImage?
	dynamic var sp: String = " "
	dynamic var wealth: String = " "
	dynamic var location: NSAttributedString?
	dynamic var subscription: String = " "
	dynamic var skill: NSAttributedString?
	dynamic var skillQueue: String = " "
	
	var firstTrainingSkill: ESSkillQueueItem? {
		didSet {
			if let skill = firstTrainingSkill {
				guard let type = NCDatabase.sharedDatabase?.invTypes[skill.skillID] else {return}
				guard let firstTrainingSkill = NCSkill(type: type, skill: skill) else {return}

				if !firstTrainingSkill.typeName.isEmpty {
					self.skill = NSAttributedString(skillName: firstTrainingSkill.typeName, level: 1 + (firstTrainingSkill.level ?? 0))
				}
				else {
					self.skill = NSAttributedString(string: String(format: NSLocalizedString("Unknown skill %d", comment: ""), firstTrainingSkill.typeID))
				}
				
				self.trainingProgress = firstTrainingSkill.trainingProgress
				if let endTime = firstTrainingSkill.trainingEndDate {
					self.trainingTime = NCTimeIntervalFormatter.localizedString(from: endTime.timeIntervalSinceNow, precision: .minutes)
				}
				else {
					self.trainingTime = " "
				}

			}
			else {
				self.skill = NSAttributedString(string: NSLocalizedString("No skills in training", comment: ""), attributes: [NSForegroundColorAttributeName: UIColor.lightText])
				self.trainingProgress = 0
				self.trainingTime = " "
			}
		}
	}
	
	dynamic var trainingProgress: Float = 0
	dynamic var trainingTime: String = " "
	dynamic var account: NCAccount
	
	private func updateLocation() {
		if let ship = ship, let solarSystem = solarSystem {
			let s = NSMutableAttributedString()
			s.append(NSAttributedString(string: ship, attributes: [NSForegroundColorAttributeName: UIColor.white]))
			s.append(NSAttributedString(string: ", \(solarSystem)", attributes: [NSForegroundColorAttributeName: UIColor.lightText]))
			self.location = s
		}
		else if let solarSystem = solarSystem {
			let s = NSAttributedString(string: solarSystem, attributes: [NSForegroundColorAttributeName: UIColor.lightText])
			self.location = s
		}
		else if let ship = ship {
			let s = NSAttributedString(string: ship, attributes: [NSForegroundColorAttributeName: UIColor.white])
			self.location = s
		}
		else {
			self.location = NSAttributedString(string: " ")
		}
	}
	
	var solarSystem: String? {
		didSet {
			updateLocation()
		}
	}
	
	var ship: String? {
		didSet {
			updateLocation()
		}
	}
	
	var characterRecord: NCCacheRecord? {
		didSet {
			if let characterRecord = characterRecord {
				self.binder.bind("characterName", toObject: characterRecord.data!, withKeyPath: "data.name", transformer: NCValueTransformer(handler: { value in
					guard let characterName = value as? String else {return characterRecord.error?.localizedDescription ?? " "}
					return characterName
				}))
			}
			else {
				self.characterName = " "
			}
		}
	}
	
	var characterError: Error? {
		didSet {
			if let characterError = characterError, self.characterRecord == nil {
				self.characterName = characterError.localizedDescription
			}
		}
	}
	
	var corporationRecord: NCCacheRecord? {
		didSet {
			if let corporationRecord = corporationRecord {
				self.binder.bind("corporation", toObject: corporationRecord.data!, withKeyPath: "data.corporationName", transformer: NCValueTransformer(handler: { value in
					guard let characterName = value as? String else {return corporationRecord.error?.localizedDescription ?? " "}
					return characterName
				}))
			}
			else {
				self.corporation = " "
			}
		}
	}
	
	var corporationError: Error? {
		didSet {
			if let corporationError = corporationError, self.corporationRecord == nil {
				self.corporation = corporationError.localizedDescription
			}
		}
	}
	
	var skillQueueRecord: NCCacheRecord? {
		didSet {
			if let skillQueueRecord = skillQueueRecord {
				self.binder.bind("firstTrainingSkill", toObject: skillQueueRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { value in
					guard let skillQueue = value as? [ESSkillQueueItem] else {return nil}
					let date = Date()
					guard let skill = skillQueue.first(where: {
						if let finishDate = $0.finishDate {
							return finishDate > date
						}
						else {
							return false
						}
					})
					else {
						return nil
					}
					return skill
				}))
				
				self.binder.bind("skillQueue", toObject: skillQueueRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { (value) -> Any? in
					let date = Date()
					guard let skillQueue = (value as? [ESSkillQueueItem])?.filter({
						guard let finishDate = $0.finishDate else {return false}
						return finishDate >= date
					})
						else {
							return skillQueueRecord.error?.localizedDescription ?? " "
					}
					guard let skill = skillQueue.last else {return " "}
					guard let endTime = skill.finishDate else {return " "}
					return String(format: NSLocalizedString("%d skills in queue (%@)", comment: ""), skillQueue.count, NCTimeIntervalFormatter.localizedString(from: endTime.timeIntervalSinceNow, precision: .minutes))
				}))
			}
			else {
				self.firstTrainingSkill = nil
				self.skillQueue = " "
			}
		}
	}
	
	var skillQueueError: Error? {
		didSet {
			if let skillQueueError = skillQueueError, self.skillQueueRecord == nil {
				self.skillQueue = skillQueueError.localizedDescription
			}
		}
	}

	var walletsRecord: NCCacheRecord? {
		didSet {
			if let walletsRecord = walletsRecord {
				self.binder.bind("wealth", toObject: walletsRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { value in
					guard let wallets = value as? [ESWallet] else {return walletsRecord.error?.localizedDescription ?? " "}
					var wealth = 0.0
					for wallet in wallets {
						wealth += wallet.balance
					}
					return NCUnitFormatter.localizedString(from: wealth, unit: .none, style: .short)
				}))
			}
			else {
				self.wealth = " "
			}
		}
	}
	
	var skillsRecord: NCCacheRecord? {
		didSet {
			if let skillsRecord = skillsRecord {
				self.binder.bind("sp", toObject: skillsRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { value in
					guard let skills = value as? ESSkills else {return skillsRecord.error?.localizedDescription ?? " "}
					return NCUnitFormatter.localizedString(from: Double(skills.totalSP), unit: .none, style: .short)
				}))
			}
			else {
				self.sp = " "
			}
		}
	}
	
	
	var characterLocationRecord: NCCacheRecord? {
		didSet {
			if let characterLocationRecord = characterLocationRecord {
				self.binder.bind("solarSystem", toObject: characterLocationRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { value in
					guard let location = value as? ESCharacterLocation else {return characterLocationRecord.error?.localizedDescription ?? nil}
					guard let solarSystem = NCDatabase.sharedDatabase?.mapSolarSystems[location.solarSystemID] else {return nil}
					return "\(solarSystem.solarSystemName!) / \(solarSystem.constellation!.region!.regionName!)"
				}))
			}
			else {
				self.solarSystem = nil
			}
		}
	}
	
	var characterShipRecord: NCCacheRecord? {
		didSet {
			if let characterShipRecord = characterShipRecord {
				self.binder.bind("ship", toObject: characterShipRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { value in
					guard let ship = value as? ESCharacterShip else {return characterShipRecord.error?.localizedDescription ?? nil}
					guard let type = NCDatabase.sharedDatabase?.invTypes[ship.shipTypeID] else {return nil}
					return type.typeName
				}))
			}
			else {
				self.ship = nil
			}
		}
	}
	
	var characterImageRecord: NCCacheRecord? {
		didSet {
			if let characterImageRecord = characterImageRecord {
				self.binder.bind("characterImage", toObject: characterImageRecord.data!, withKeyPath: "data", transformer: NCImageFromDataValueTransformer())
			}
			else {
				self.characterImage = nil
			}
		}
	}
	
	/*var accountStatusRecord: NCCacheRecord? {
		didSet {
			if let accountStatusRecord = accountStatusRecord {
				self.binder.bind("subscription", toObject: accountStatusRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { (value) -> Any? in
					guard let accountStatus = value as? EVEAccountStatus else {return accountStatusRecord.error?.localizedDescription ?? " "}
					let t = accountStatus.paidUntil.timeIntervalSinceNow
					if t > 0 {
						return "\(DateFormatter.localizedString(from: accountStatus.paidUntil, dateStyle: .medium, timeStyle: .none)) (\(NCTimeIntervalFormatter.localizedString(from: t, precision: .days)))"
					}
					else {
						return NSLocalizedString("expired", comment: "")
					}
				}))
			}
			else {
				self.subscription = " "
			}
		}
	}
	
	var characterInfoRecord: NCCacheRecord? {
		didSet {
			if let characterInfoRecord = characterInfoRecord {
				self.binder.bind("characterName", toObject: characterInfoRecord.data!, withKeyPath: "data.characterName", transformer: NCValueTransformer(handler: { (value) -> Any? in
					guard let characterName = value as? String else {return characterInfoRecord.error?.localizedDescription ?? " "}
					return characterName
				}))
				
				self.binder.bind("corporation", toObject: characterInfoRecord.data!, withKeyPath: "data.corporation", transformer: NCValueTransformer(handler: { (value) -> Any? in
					if let s = value as? String, !s.isEmpty {
						return s
					}
					else {
						return " "
					}
				}))
				
				self.binder.bind("sp", toObject: characterInfoRecord.data!, withKeyPath: "data.skillPoints", transformer: NCValueTransformer(handler: { (value) -> Any? in
					guard let sp = value as? Double else {return " "}
					return NCUnitFormatter.localizedString(from: sp, unit: .none, style: .short)
				}))

				self.binder.bind("wealth", toObject: characterInfoRecord.data!, withKeyPath: "data.accountBalance", transformer: NCValueTransformer(handler: { (value) -> Any? in
					guard let wealth = value as? Double else {return " "}
					return NCUnitFormatter.localizedString(from: wealth, unit: .none, style: .short)
				}))

				self.binder.bind("location", toObject: characterInfoRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { (value) -> Any? in
					guard let characterInfo = value as? EVECharacterInfo else {return " "}
					if !characterInfo.lastKnownLocation.isEmpty && !characterInfo.shipTypeName.isEmpty {
						let s = NSMutableAttributedString()
						s.append(NSAttributedString(string: characterInfo.shipTypeName, attributes: [NSForegroundColorAttributeName: UIColor.white]))
						s.append(NSAttributedString(string: ", \(characterInfo.lastKnownLocation)", attributes: [NSForegroundColorAttributeName: UIColor.lightText]))
						return s
					}
					else if !characterInfo.lastKnownLocation.isEmpty {
						return NSAttributedString(string: characterInfo.lastKnownLocation, attributes: [NSForegroundColorAttributeName: UIColor.lightText])
					}
					else if !characterInfo.shipTypeName.isEmpty {
						return NSAttributedString(string: characterInfo.shipTypeName, attributes: [NSForegroundColorAttributeName: UIColor.white])
					}
					else {
						return NSAttributedString(string: " ")
					}
				}))

			}
			else {
				self.subscription = " "
				self.corporation = " "
				self.sp = " "
				self.wealth = " "
				self.location = NSAttributedString(string: " ")
			}
		}
	}
	var skillQueueRecord: NCCacheRecord? {
		didSet {
			if let skillQueueRecord = skillQueueRecord {
				self.binder.bind("firstTrainingSkill", toObject: skillQueueRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { (value) -> Any? in
					guard let skillQueue = value as? EVESkillQueue else {return nil}
					if let firstSkill = skillQueue.skillQueue.first, let type = NCDatabase.sharedDatabase?.invTypes[firstSkill.typeID] {
						return NCSkill(type: type, skill: firstSkill)
					}
					else {
						return nil
					}
				}))
				
				self.binder.bind("skillQueue", toObject: skillQueueRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { (value) -> Any? in
					guard let skillQueue = value as? EVESkillQueue else {return skillQueueRecord.error?.localizedDescription ?? " "}
					if let firstSkill = skillQueue.skillQueue.first {
						let endTime = firstSkill.endTime
						return String(format: NSLocalizedString("%d skills in queue (%@)", comment: ""), skillQueue.skillQueue.count, NCTimeIntervalFormatter.localizedString(from: endTime.timeIntervalSinceNow, precision: .minutes))
					}
					else {
						return " "
					}
				}))
			}
			else {
				self.firstTrainingSkill = nil
				self.skillQueue = " "
			}
		}
	}
	
	var accountBalanceRecord: NCCacheRecord? {
		didSet {
			if let accountBalanceRecord = accountBalanceRecord {
				self.binder.bind("wealth", toObject: accountBalanceRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { (value) -> Any? in
					guard let accountBalance = value as? EVEAccountBalance else {return accountBalanceRecord.error?.localizedDescription ?? " "}
					var isk = 0.0
					for account in accountBalance.accounts {
						isk += account.balance
					}
					return NCUnitFormatter.localizedString(from: isk, unit: .none, style: .short)
				}))
			}
			else {
				self.wealth = " "
			}
		}
	}
	var characterImageRecord: NCCacheRecord? {
		didSet {
			if let characterImageRecord = characterImageRecord {
				self.binder.bind("characterImage", toObject: characterImageRecord.data!, withKeyPath: "data", transformer: NCImageFromDataValueTransformer())
			}
			else {
				self.characterImage = nil
			}
		}
	}
	var corporationImageRecord: NCCacheRecord? {
		didSet {
			if let characterImageRecord = characterImageRecord {
				self.binder.bind("characterImage", toObject: characterImageRecord.data!, withKeyPath: "data", transformer: NCImageFromDataValueTransformer())
			}
			else {
				self.characterImage = nil
			}
		}
	}*/
	
	private(set) lazy var binder: NCBinder = {
		return NCBinder(target: self)
	}()
	
	init(account: NCAccount) {
		self.account = account
		/*self.corporate = account.eveAPIKey.corporate
		if self.corporate, let character = account.character {
			self.corporation = character.corporationName
			self.alliance = character.allianceName
		}*/
		super.init()
	}
}

class NCAccountsViewController: UITableViewController, NSFetchedResultsControllerDelegate, UIViewControllerTransitioningDelegate {
	private var results: NSFetchedResultsController<NCAccount>?
	private var accountsInfo: [NSManagedObjectID: NCAccountInfo] = [:]
	private var isInteractive: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if results == nil {
			if let context = NCStorage.sharedStorage?.viewContext {
				let request = NSFetchRequest<NCAccount>(entityName: "Account")
				request.sortDescriptors = [NSSortDescriptor(key: "characterName", ascending: true)]
				
				let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "characterName", cacheName: nil)
				results.delegate = self
				try? results.performFetch()
				self.results = results
				self.accountsInfo = [:]
				self.tableView.reloadData()
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		navigationController?.transitioningDelegate = self
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	@IBAction func onAddAccount(_ sender: Any) {
		UIApplication.shared.openURL(ESAPI.oauth2url(clientID: ESClientID, callbackURL: ESCallbackURL, scope: ESScope.all))
	}

	@IBAction func onClose(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
	
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.results?.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.results?.sections?[section].numberOfObjects ?? 0
    }

	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NCAccountTableViewCell
		cell.characterNameLabel.text = " "
		cell.characterImageView.image = nil
		cell.corporationLabel.text = " "
		cell.spLabel.text = " "
		cell.wealthLabel.text = " "
		cell.locationLabel.text = " "
		cell.subscriptionLabel.text = " "
		cell.skillLabel.text = " "
		cell.trainingTimeLabel.text = " "
		cell.skillQueueLabel.text = " "
		cell.trainingProgressView.progress = 0
		cell.progressHandler = nil
		
		let account = results!.object(at: indexPath)
		
		var accountInfo = accountsInfo[account.objectID]
		if accountInfo == nil {
			accountInfo = NCAccountInfo(account: account)
			
			let progressHandler = NCProgressHandler(view: cell, totalUnitCount: 1)
			cell.progressHandler = progressHandler
			progressHandler.progress.becomeCurrent(withPendingUnitCount: 1)
			loadAccountInfo(accountInfo!) {
				progressHandler.finish()
				if cell.progressHandler === progressHandler {
					cell.progressHandler = nil
				}
			}
			progressHandler.progress.resignCurrent()
			accountsInfo[account.objectID] = accountInfo!
		}
		
		cell.binder.bind("characterNameLabel.text", toObject: accountInfo!, withKeyPath: "characterName", transformer: nil)
		cell.binder.bind("corporationLabel.text", toObject: accountInfo!, withKeyPath: "corporation", transformer: nil)
		cell.binder.bind("skillLabel.attributedText", toObject: accountInfo!, withKeyPath: "skill", transformer: nil)
		cell.binder.bind("skillQueueLabel.text", toObject: accountInfo!, withKeyPath: "skillQueue", transformer: nil)
		cell.binder.bind("trainingTimeLabel.text", toObject: accountInfo!, withKeyPath: "trainingTime", transformer: nil)
		cell.binder.bind("trainingProgressView.progress", toObject: accountInfo!, withKeyPath: "trainingProgress", transformer: nil)
		cell.binder.bind("wealthLabel.text", toObject: accountInfo!, withKeyPath: "wealth", transformer: nil)
		cell.binder.bind("spLabel.text", toObject: accountInfo!, withKeyPath: "sp", transformer: nil)
		cell.binder.bind("locationLabel.attributedText", toObject: accountInfo!, withKeyPath: "location", transformer: nil)
		cell.binder.bind("characterImageView.image", toObject: accountInfo!, withKeyPath: "characterImage", transformer: nil)
        return cell
    }
	
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
	
	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		return .delete
	}
	
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
			let account = results!.object(at: indexPath)
			account.managedObjectContext?.delete(account)
			try? account.managedObjectContext?.save()
            //tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
        }
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		NCAccount.current = results!.object(at: indexPath)
		dismiss(animated: true, completion: nil)
	}

	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let bottom = max(scrollView.contentSize.height - scrollView.bounds.size.height, 0)
		let y = scrollView.contentOffset.y - bottom
		if (y > 40 && transitionCoordinator == nil && scrollView.isTracking) {
			self.isInteractive = true
			dismiss(animated: true, completion: nil)
			self.isInteractive = false
		}
	}
	
	// MARK: NSFetchedResultsControllerDelegate
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		switch type {
		case .insert:
			tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
		case .delete:
			tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
		default:
			break
		}
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			tableView.insertRows(at: [newIndexPath!], with: .automatic)
		case .delete:
			tableView.deleteRows(at: [indexPath!], with: .automatic)
		case .update:
			tableView.reloadRows(at: [indexPath!], with: .automatic)
		case .move:
			tableView.deleteRows(at: [indexPath!], with: .automatic)
			tableView.insertRows(at: [newIndexPath!], with: .automatic)
		}
	}

	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
	
	// MARK: UIViewControllerTransitioningDelegate
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return NCSlideDownAnimationController()
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return isInteractive ? NCSlideDownInteractiveTransition(scrollView: self.tableView) : nil
	}
	
	// MARK: Private
	
	private func loadAccountInfo(_ accountInfo: NCAccountInfo, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil) {
		let progress = Progress(totalUnitCount: 8)
		
		let dataManager = NCDataManager(account: accountInfo.account, cachePolicy: cachePolicy)
		
		progress.becomeCurrent(withPendingUnitCount: 1)
		dataManager.character { result in
			switch result {
			case let .success(value, cacheRecord):
				let dispatchGroup = DispatchGroup()
				accountInfo.characterRecord = cacheRecord
				
				dispatchGroup.enter()
				progress.becomeCurrent(withPendingUnitCount: 1)
				dataManager.corporation(corporationID: value.corporationID) { result in
					switch result {
					case let .success(_, cacheRecord):
						accountInfo.corporationRecord = cacheRecord
					case let .failure(error):
						accountInfo.corporationError = error
					}
					dispatchGroup.leave()
				}
				progress.resignCurrent()
				
				dispatchGroup.enter()
				progress.becomeCurrent(withPendingUnitCount: 1)
				dataManager.skillQueue { result in
					switch result {
					case let .success(_, cacheRecord):
						accountInfo.skillQueueRecord = cacheRecord
					case let .failure(error):
						accountInfo.skillQueueError = error
					}
					dispatchGroup.leave()
				}
				progress.resignCurrent()

				dispatchGroup.enter()
				progress.becomeCurrent(withPendingUnitCount: 1)
				dataManager.wallets { result in
					switch result {
					case let .success(_, cacheRecord):
						accountInfo.walletsRecord = cacheRecord
					case .failure:
						break
					}
					dispatchGroup.leave()
				}
				progress.resignCurrent()
				
				dispatchGroup.enter()
				progress.becomeCurrent(withPendingUnitCount: 1)
				dataManager.skills { result in
					switch result {
					case let .success(_, cacheRecord):
						accountInfo.skillsRecord = cacheRecord
					case .failure:
						break
					}
					dispatchGroup.leave()
				}
				progress.resignCurrent()
				
				dispatchGroup.enter()
				progress.becomeCurrent(withPendingUnitCount: 1)
				dataManager.characterLocation { result in
					switch result {
					case let .success(_, cacheRecord):
						accountInfo.characterLocationRecord = cacheRecord
					case .failure:
						break
					}
					dispatchGroup.leave()
				}
				progress.resignCurrent()
				
				dispatchGroup.enter()
				progress.becomeCurrent(withPendingUnitCount: 1)
				dataManager.characterShip { result in
					switch result {
					case let .success(_, cacheRecord):
						accountInfo.characterShipRecord = cacheRecord
					case .failure:
						break
					}
					dispatchGroup.leave()
				}
				progress.resignCurrent()
				
				dispatchGroup.enter()
				progress.becomeCurrent(withPendingUnitCount: 1)
				dataManager.image(characterID: accountInfo.account.characterID, dimension: 80) { result in
					switch result {
					case let .success(_, cacheRecord):
						accountInfo.characterImageRecord = cacheRecord
					case .failure:
						break
					}
					dispatchGroup.leave()
				}
				progress.resignCurrent()
				
				dispatchGroup.notify(queue: .main) {
					completionHandler?()
				}

			case let .failure(error):
				accountInfo.characterError = error
				progress.completedUnitCount = progress.totalUnitCount
				completionHandler?()
				break
			}
		}
		progress.resignCurrent()
	}
	
}
