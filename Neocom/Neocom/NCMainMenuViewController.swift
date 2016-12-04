//
//  NCMainMenuViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCMainMenuDetails: NSObject {
	let account: NCAccount?
	var binder: NCBinder!
	dynamic var skillPoints: String?
	dynamic var skillQueueInfo: String?
	dynamic var unreadMails: String?
	dynamic var balance: String?
	dynamic var jumpClones: String?

	var characterSheet: NCCacheRecord? {
		didSet {
			if let characterSheet = characterSheet {
				self.binder.bind("jumpClones", toObject: characterSheet.data!, withKeyPath: "data", transformer: NCValueTransformer { (value) -> Any? in
					if let value = value as? EVECharacterSheet {
						let t = value.cloneJumpDate.timeIntervalSinceNow + 3600 * 24
						return String.init(format: NSLocalizedString("Clone jump availability: %@", comment: ""), t > 0 ? NCTimeIntervalFormatter.localizedString(from: t, precision: .Minutes) : NSLocalizedString("Now", comment: ""))
					}
					else {
						return characterSheet.error?.localizedDescription
					}
				})
			}
			else {
				self.binder.unbind("jumpClones")
				self.jumpClones = nil
			}
		}
	}
	var characterInfo: NCCacheRecord? {
		didSet {
			if let characterInfo = characterInfo {
				self.binder.bind("skillPoints", toObject: characterInfo.data!, withKeyPath: "data.skillPoints", transformer: NCValueTransformer { (value) -> Any? in
					if let value = value as? Double {
						return NCUnitFormatter.localizedString(from: value, unit: .SkillPoints, style: .Full)
					}
					else {
						return characterInfo.error?.localizedDescription
					}
				})
			}
			else {
				self.binder.unbind("skillPoints")
				self.binder.unbind("balance")
				self.skillPoints = nil
				self.balance = nil
			}
		}
	}
	
	var skillQueue: NCCacheRecord? {
		didSet {
			if let skillQueue = skillQueue {
				self.binder.bind("skillQueueInfo", toObject: skillQueue.data!, withKeyPath: "data", transformer: NCValueTransformer { (value) -> Any? in
					if let value = value as? EVESkillQueue {
						if let lastSkill = value.skillQueue.last {
							return String.init(format: "%d skills in queue (%@)", value.skillQueue.count, NCTimeIntervalFormatter.localizedString(from: lastSkill.endTime.timeIntervalSinceNow, precision: .Minutes))
						}
						else {
							return NSLocalizedString("No skills in training", comment: "")
						}
					}
					else {
						return skillQueue.error?.localizedDescription
					}
				})
			}
			else {
				self.binder.unbind("skillQueueInfo")
				self.skillQueueInfo = nil
			}
		}
	}
	
	var accountBalance: NCCacheRecord? {
		didSet {
			if let accountBalance = accountBalance {
				self.binder.bind("balance", toObject: accountBalance.data!, withKeyPath: "data", transformer: NCValueTransformer { (value) -> Any? in
					if let value = value as? EVEAccountBalance {
						var isk = 0.0
						for account in value.accounts {
							isk += account.balance
						}
						return NCUnitFormatter.localizedString(from: isk, unit: .ISK, style: .Full)
					}
					else {
						return accountBalance.error?.localizedDescription
					}
				})
			}
			else {
				self.binder.unbind("balance")
				self.balance = nil
			}
		}
	}

	init(account: NCAccount) {
		self.account = account
		super.init()
		self.binder = NCBinder(target: self)
	}
}

class NCMainMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	@IBOutlet weak var tableView: NCTableView!
	private weak var mainMenuHeaderViewController: NCMainMenuHeaderViewController? = nil
	private var headerMinHeight: CGFloat = 0
	private var headerMaxHeight: CGFloat = 0
	private var mainMenu: [[[String: Any]]] = []
	private var mainMenuDetails: NCMainMenuDetails? = nil
	private var interactive: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.estimatedRowHeight = self.tableView.rowHeight
		self.tableView.rowHeight = UITableViewAutomaticDimension
		updateHeader()
		NSNotification.Name.NSManagedObjectContextDidSave
		//NotificationCenter.default.addObserver(self, selector: #selector(updateHeader), name: NSNotification.Name., object: <#T##Any?#>)
		loadMenu()
	}
	
	//MARK: UITableViewDataSource
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return self.mainMenu.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.mainMenu[section].count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NCTableViewDefaultCell
		let row = self.mainMenu[indexPath.section][indexPath.row]
		cell.titleLabel?.text = row["title"] as? String
		if let detailsKeyPath = row["detailsKeyPath"] as? String, let mainMenuDetails = self.mainMenuDetails {
			cell.binder.bind("subtitleLabel.text", toObject: mainMenuDetails, withKeyPath: detailsKeyPath, transformer: nil)
		}
		else {
			cell.subtitleLabel?.text = nil
		}
		if let image = row["image"] as? String {
			cell.iconView?.image = UIImage.init(named: image)
		}
		return cell
	}
	
	//MARK: Private
	
	private func updateHeader() {
		
	}
	
	private func loadMenu() {
		let corporate: Bool
		let apiKeyAccessMask: Int
		if let account = NCAccount.currentAccount {
			corporate = account.eveAPIKey.corporate
			apiKeyAccessMask = account.apiKey!.apiKeyInfo!.key.accessMask
		}
		else {
			corporate = false
			apiKeyAccessMask = 0
		}
		let accessMaskKey = corporate ? "corpAccessMask" : "charAccessMask"
		let mainMenu = NSArray.init(contentsOf: Bundle.main.url(forResource: "mainMenu", withExtension: "plist")!) as! [[[String: Any]]]
		var sections = [[[String: Any]]]()
		for section in mainMenu {
			let rows = section.filter({ (row) -> Bool in
				if let accessMask = row[accessMaskKey] as? Int, accessMask & apiKeyAccessMask == accessMask {
					return true
				}
				else {
					return false
				}
			})
			if rows.count > 0 {
				sections.append(rows)
			}
		}
		
		self.mainMenu = sections
	}

}
