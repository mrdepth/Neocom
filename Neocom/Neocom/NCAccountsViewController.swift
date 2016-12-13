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
	dynamic var skillColor: UIColor = UIColor.white
	dynamic var skillQueue: String = " "
	
	var firstTrainingSkill: ESSkillQueueItem? {
		didSet {
			if let skill = firstTrainingSkill {
				guard let type = NCDatabase.sharedDatabase?.invTypes[skill.skillID] else {return}
				guard let firstTrainingSkill = NCSkill(type: type, skill: skill) else {return}

				if !firstTrainingSkill.typeName.isEmpty {
					self.skill = NSAttributedString(skillName: firstTrainingSkill.typeName, level: firstTrainingSkill.level + 1)
				}
				else {
					self.skill = NSAttributedString(string: String(format: NSLocalizedString("Unknown skill %d", comment: ""), firstTrainingSkill.typeID))
				}
				
				self.skillColor = UIColor.white
				self.trainingProgress = firstTrainingSkill.trainingProgress
				if let endTime = firstTrainingSkill.trainingEndDate {
					self.trainingTime = NCTimeIntervalFormatter.localizedString(from: endTime.timeIntervalSinceNow, precision: .minutes)
				}
				else {
					self.trainingTime = " "
				}

			}
			else {
				self.skill = NSAttributedString(string: NSLocalizedString("No skills in training", comment: ""))
				self.skillColor = UIColor.lightText
				self.trainingProgress = 0
				self.trainingTime = " "
			}
		}
	}
	
	dynamic var trainingProgress: Double = 0
	dynamic var trainingTime: String = " "
	dynamic var account: NCAccount
	
	var solarSystem: String? {
		didSet {
			
		}
	}
	
	var ship: String? {
		didSet {
			if let ship = ship, let solarSystem = solarSystem {
				let s = NSMutableAttributedString()
				s.append(NSAttributedString(string: ship, attributes: [NSForegroundColorAttributeName: UIColor.white]))
				s.append(NSAttributedString(string: ", \(solarSystem)", attributes: [NSForegroundColorAttributeName: UIColor.lightText]))
				self.location = s
			}
			guard let characterInfo = value as? EVECharacterInfo else {return " "}
			if !characterInfo.lastKnownLocation.isEmpty && !characterInfo.shipTypeName.isEmpty {
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
					guard let skillQueue = value as? [ESSkillQueueItem] else {return skillQueueRecord.error?.localizedDescription ?? " "}
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
					return solarSystem.solarSystemName
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

class NCAccountsViewController: UITableViewController, NSFetchedResultsControllerDelegate {
	private var results: NSFetchedResultsController<NCAccount>?
	private var accountsInfo: [NSManagedObjectID: NCAccountInfo] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if results == nil {
			if let context = NCStorage.sharedStorage?.viewContext {
				let request = NSFetchRequest<NCAccount>(entityName: "Account")
				request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
				
				let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "Order", cacheName: nil)
				try? results.performFetch()
				self.results = results
				self.accountsInfo = [:]
				self.tableView.reloadData()
			}
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NCAccountCell
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
		
		let account = results!.object(at: indexPath)
		
		var accountInfo = accountsInfo[account.objectID]
		if accountInfo == nil {
			accountInfo = NCAccountInfo(account: account)
			loadAccountInfo(accountInfo!)
			accountsInfo[account.objectID] = accountInfo!
		}
		
		cell.binder.bind("characterNameLabel.text", toObject: accountInfo!, withKeyPath: "characterName", transformer: nil)
		cell.binder.bind("corporationLabel.text", toObject: accountInfo!, withKeyPath: "corporation", transformer: nil)
		cell.binder.bind("skillLabel.textColor", toObject: accountInfo!, withKeyPath: "skillColor", transformer: nil)
		cell.binder.bind("skillLabel.attributedText", toObject: accountInfo!, withKeyPath: "skill", transformer: nil)
		cell.binder.bind("skillQueueLabel.text", toObject: accountInfo!, withKeyPath: "skillQueue", transformer: nil)
		cell.binder.bind("trainingTimeLabel.text", toObject: accountInfo!, withKeyPath: "trainingTime", transformer: nil)
		cell.binder.bind("trainingProgressView.progress", toObject: accountInfo!, withKeyPath: "trainingProgress", transformer: nil)
		cell.binder.bind("wealthLabel.text", toObject: accountInfo!, withKeyPath: "wealth", transformer: nil)
		cell.binder.bind("spLabel.text", toObject: accountInfo!, withKeyPath: "sp", transformer: nil)
        return cell
    }
	

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
	
	// MARK: Private
	
	private func loadAccountInfo(_ accountInfo: NCAccountInfo, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil) {
		let progress = Progress(totalUnitCount: 2)
		
		let dataManager = NCDataManager()
		
		progress.becomeCurrent(withPendingUnitCount: 1)
		dataManager.character(account: accountInfo.account, cachePolicy: cachePolicy) { result in
			switch result {
			case let .success(value: value, cacheRecordID: recordID):
				accountInfo.characterRecord = (try? NCCache.sharedCache?.viewContext.existingObject(with: recordID)) as? NCCacheRecord
				
				dataManager.corporation(corporationID: value.corporationID, account: accountInfo.account, cachePolicy: cachePolicy) { result in
					switch result {
					case let .success(value: _, cacheRecordID: recordID):
						accountInfo.corporationRecord = (try? NCCache.sharedCache?.viewContext.existingObject(with: recordID)) as? NCCacheRecord
					case let .failure(error):
						accountInfo.corporationError = error
					}
				}
				
				dataManager.skillQueue(account: accountInfo.account, cachePolicy: cachePolicy) { result in
					switch result {
					case let .success(value: _, cacheRecordID: recordID):
						accountInfo.skillQueueRecord = (try? NCCache.sharedCache?.viewContext.existingObject(with: recordID)) as? NCCacheRecord
					case let .failure(error):
						accountInfo.skillQueueError = error
					}
				}
				
				dataManager.wallets(account: accountInfo.account, cachePolicy: cachePolicy) { result in
					switch result {
					case let .success(value: _, cacheRecordID: recordID):
						accountInfo.walletsRecord = (try? NCCache.sharedCache?.viewContext.existingObject(with: recordID)) as? NCCacheRecord
					case .failure:
						break
					}
				}

				dataManager.skills(account: accountInfo.account, cachePolicy: cachePolicy) { result in
					switch result {
					case let .success(value: _, cacheRecordID: recordID):
						accountInfo.skillsRecord = (try? NCCache.sharedCache?.viewContext.existingObject(with: recordID)) as? NCCacheRecord
					case .failure:
						break
					}
				}
			case let .failure(error):
				accountInfo.characterError = error
				progress.completedUnitCount += 1
				completionHandler?()
				break
			}
		}
		progress.resignCurrent()
	}
	
}
