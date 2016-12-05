//
//  NCAccountsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCAccountInfo: NSObject {
	dynamic var corporate: Bool
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
	
	var firstTrainingSkill: NCSkill? {
		didSet {
			if let firstTrainingSkill = firstTrainingSkill {
				if !firstTrainingSkill.typeName.isEmpty {
					self.skill = NSAttributedString(skillName: firstTrainingSkill.typeName, level: firstTrainingSkill.level + 1)
				}
				else {
					self.skill = NSAttributedString(string: String(format: NSLocalizedString("Unknown skill %d", comment: ""), firstTrainingSkill.typeID))
				}
				
				self.skillColor = UIColor.white
				self.trainingProgress = firstTrainingSkill.trainingProgress
				if let endTime = firstTrainingSkill.trainingEndDate {
					self.trainingTime = NCTimeIntervalFormatter.localizedString(from: endTime.timeIntervalSinceNow, precision: .Minutes)
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
	
	var accountStatusRecord: NCCacheRecord? {
		didSet {
			if let accountStatusRecord = accountStatusRecord {
				self.binder.bind("subscription", toObject: accountStatusRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { (value) -> Any? in
					guard let accountStatus = value as? EVEAccountStatus else {return accountStatusRecord.error?.localizedDescription ?? " "}
					let t = accountStatus.paidUntil.timeIntervalSinceNow
					if t > 0 {
						return "\(DateFormatter.localizedString(from: accountStatus.paidUntil, dateStyle: .medium, timeStyle: .none)) (\(NCTimeIntervalFormatter.localizedString(from: t, precision: .Days)))"
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
					return NCUnitFormatter.localizedString(from: sp, unit: .None, style: .Short)
				}))

				self.binder.bind("wealth", toObject: characterInfoRecord.data!, withKeyPath: "data.accountBalance", transformer: NCValueTransformer(handler: { (value) -> Any? in
					guard let wealth = value as? Double else {return " "}
					return NCUnitFormatter.localizedString(from: wealth, unit: .None, style: .Short)
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
						return String(format: NSLocalizedString("%d skills in queue (%@)", comment: ""), skillQueue.skillQueue.count, NCTimeIntervalFormatter.localizedString(from: endTime.timeIntervalSinceNow, precision: .Minutes))
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
					return NCUnitFormatter.localizedString(from: isk, unit: .None, style: .Short)
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
	}
	
	private(set) lazy var binder: NCBinder = {
		return NCBinder(target: self)
	}()
	
	init(account: NCAccount) {
		self.account = account
		self.corporate = account.eveAPIKey.corporate
		if self.corporate, let character = account.character {
			self.corporation = character.corporationName
			self.alliance = character.allianceName
		}
		super.init()
	}
}

class NCAccountsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

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

}
