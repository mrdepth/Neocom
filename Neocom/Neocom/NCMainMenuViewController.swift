//
//  NCMainMenuViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCMainMenuDetails: NSObject {
	let account: NCAccount
	dynamic var skillPoints: String?
	dynamic var skillQueueInfo: String?
	dynamic var unreadMails: String?
	dynamic var balance: String?
	dynamic var jumpClones: String?

	private(set) lazy var binder: NCBinder = {
		return NCBinder(target: self)
	}()
	
	var skillsRecord: NCCacheRecord? {
		didSet {
			if let skillsRecord = skillsRecord {
				self.binder.bind("skillPoints", toObject: skillsRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { value in
					guard let skills = value as? ESI.Skills.CharacterSkills else {return skillsRecord.error?.localizedDescription ?? nil}
					return NCUnitFormatter.localizedString(from: Double(skills.totalSP ?? 0), unit: .skillPoints, style: .full)
				}))
			}
			else {
				self.skillPoints = nil
			}
		}
	}
	
	var clonesRecord: NCCacheRecord? {
		didSet {
			if let clonesRecord = clonesRecord {
				self.binder.bind("jumpClones", toObject: clonesRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { value in
					guard let clones = value as? ESI.Clones.JumpClones else {return clonesRecord.error?.localizedDescription ?? nil}
					let t = 3600 * 24 + (clones.lastJumpDate ?? .distantPast).timeIntervalSinceNow
					return String(format: NSLocalizedString("Clone jump availability: %@", comment: ""), t > 0 ? NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes) : NSLocalizedString("Now", comment: ""))
				}))
			}
			else {
				self.jumpClones = nil
			}
		}
	}
	
	var skillQueueRecord: NCCacheRecord? {
		didSet {
			if let skillQueueRecord = skillQueueRecord {
				self.binder.bind("skillQueueInfo", toObject: skillQueueRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { value in
					let date = Date()
					
					guard let skillQueue = (value as? [ESI.Skills.SkillQueueItem])?.filter({
						guard let finishDate = $0.finishDate else {return false}
						return finishDate >= date
					}),
							let skill = skillQueue.last,
							let endTime = skill.finishDate
						else
					{
						return NSLocalizedString("No skills in training", comment: "")
					}
					
					return String(format: NSLocalizedString("%d skills in queue (%@)", comment: ""), skillQueue.count, NCTimeIntervalFormatter.localizedString(from: endTime.timeIntervalSinceNow, precision: .minutes))
				}))
			}
			else {
				self.skillQueueInfo = nil
			}
		}
	}
	
	var walletBalanceRecord: NCCacheRecord? {
		didSet {
			if let walletsRecord = walletBalanceRecord {
				self.binder.bind("balance", toObject: walletsRecord.data!, withKeyPath: "data", transformer: NCValueTransformer(handler: { value in
					guard let walletBalance = value as? Float else {return nil}
					let wealth = Double(walletBalance)
					return NCUnitFormatter.localizedString(from: wealth, unit: .isk, style: .full)
				}))
			}
			else {
				self.balance = nil
			}
		}
	}
	
	/*var characterSheet: NCCacheRecord? {
		didSet {
			if let characterSheet = characterSheet {
				self.binder.bind("jumpClones", toObject: characterSheet.data!, withKeyPath: "data", transformer: NCValueTransformer { (value) -> Any? in
					if let value = value as? EVECharacterSheet {
						let t = value.cloneJumpDate.timeIntervalSinceNow + 3600 * 24
						return String.init(format: NSLocalizedString("Clone jump availability: %@", comment: ""), t > 0 ? NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes) : NSLocalizedString("Now", comment: ""))
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
						return NCUnitFormatter.localizedString(from: value, unit: .skillPoints, style: .full)
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
							return String.init(format: "%d skills in queue (%@)", value.skillQueue.count, NCTimeIntervalFormatter.localizedString(from: lastSkill.endTime.timeIntervalSinceNow, precision: .minutes))
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
						return NCUnitFormatter.localizedString(from: isk, unit: .isk, style: .full)
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
	}*/

	init(account: NCAccount) {
		self.account = account
		super.init()
	}
}

class NCMainMenuRow: DefaultTreeRow {
	let scopes: Set<ESI.Scope>
	let account: NCAccount?
	init(prototype: Prototype = Prototype.NCDefaultTableViewCell.default, nodeIdentifier: String, image: UIImage, title: String, route: Route, scopes: [ESI.Scope] = [], account: NCAccount? = nil) {
		self.scopes = Set(scopes)
		self.account = account
		super.init(prototype: prototype, nodeIdentifier: nodeIdentifier, image: image, title: title, accessoryType: .disclosureIndicator, route: route)
	}
}

class NCAccountDataMenuRow<T>: NCMainMenuRow {
	private var observer: NCManagedObjectObserver?
	var isLoading = false

	var result: NCCachedResult<T>? {
		didSet {
			if let cacheRecord = result?.cacheRecord {
				self.observer = NCManagedObjectObserver(managedObject: cacheRecord) { [weak self] _ in
					guard let strongSelf = self else {return}
					strongSelf.treeController?.reloadCells(for: [strongSelf], with: .none)
				}
			}
		}
	}
}

class NCCharacterSheetMenuRow: NCAccountDataMenuRow<ESI.Skills.CharacterSkills> {

	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}

		if let result = result {
			if let value = result.value {
				cell.subtitleLabel?.text = NCUnitFormatter.localizedString(from: value.totalSP ?? 0, unit: .skillPoints, style: .full)
			}
			else {
				cell.subtitleLabel?.text = result.error?.localizedDescription
			}
		}
		else {
			guard let account = account, !isLoading else {return}
			isLoading = true
			NCDataManager(account: account).skills { result in
				self.result = result
				self.isLoading = false
				self.treeController?.reloadCells(for: [self], with: .none)
			}
		}
	}
}

class NCJumpClonesMenuRow: NCAccountDataMenuRow<ESI.Clones.JumpClones> {
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		
		if let result = result {
			if let value = result.value {
				let t = 3600 * 24 + (value.lastJumpDate ?? .distantPast).timeIntervalSinceNow
				cell.subtitleLabel?.text = String(format: NSLocalizedString("Clone jump availability: %@", comment: ""), t > 0 ? NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes) : NSLocalizedString("Now", comment: ""))
			}
			else {
				cell.subtitleLabel?.text = result.error?.localizedDescription
			}
		}
		else {
			guard let account = account, !isLoading else {return}
			isLoading = true
			NCDataManager(account: account).clones { result in
				self.result = result
				self.isLoading = false
				self.treeController?.reloadCells(for: [self], with: .none)
			}
		}
	}
}

class NCSkillsMenuRow: NCAccountDataMenuRow<[ESI.Skills.SkillQueueItem]> {
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		
		if let result = result {
			if let value = result.value {
				let date = Date()
				
				let skillQueue = value.filter {
					guard let finishDate = $0.finishDate else {return false}
					return finishDate >= date
				}
				
				if let skill = skillQueue.last,
					let endTime = skill.finishDate {
					cell.subtitleLabel?.text = String(format: NSLocalizedString("%d skills in queue (%@)", comment: ""), skillQueue.count, NCTimeIntervalFormatter.localizedString(from: endTime.timeIntervalSinceNow, precision: .minutes))
				}
					else {
					cell.subtitleLabel?.text = NSLocalizedString("No skills in training", comment: "")
				}
				
			}
			else {
				cell.subtitleLabel?.text = result.error?.localizedDescription
			}
		}
		else {
			guard let account = account, !isLoading else {return}
			isLoading = true
			NCDataManager(account: account).skillQueue { result in
				self.result = result
				self.isLoading = false
				self.treeController?.reloadCells(for: [self], with: .none)
			}
		}
	}
}

class NCWealthMenuRow: NCAccountDataMenuRow<Float> {
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		
		if let result = result {
			if let value = result.value {
				cell.subtitleLabel?.text = NCUnitFormatter.localizedString(from: value, unit: .isk, style: .full)
			}
			else {
				cell.subtitleLabel?.text = result.error?.localizedDescription
			}
		}
		else {
			guard let account = account, !isLoading else {return}
			isLoading = true
			NCDataManager(account: account).walletBalance { result in
				self.result = result
				self.isLoading = false
				self.treeController?.reloadCells(for: [self], with: .none)
			}
		}
	}
}

class NCMainMenuViewController: NCTreeViewController, UIViewControllerTransitioningDelegate {
	
	private weak var headerViewController: NCMainMenuHeaderViewController?
	private var headerMinHeight: CGFloat = 0
	private var headerMaxHeight: CGFloat = 0
	private var mainMenu: [[[String: Any]]] = []
	private var mainMenuDetails: NCMainMenuDetails? = nil
	private var isInteractive: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .update
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default])
		
		updateHeader()
		loadMenu()
//		NotificationCenter.default.addObserver(self, selector: #selector(currentAccountChanged(_:)), name: .NCCurrentAccountChanged, object: nil)
		if let context = NCStorage.sharedStorage?.viewContext {
			NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: nil)
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let rect = CGRect(x: 0, y: tableView.contentOffset.y, width: self.view.bounds.size.width, height: max(self.headerMaxHeight - self.tableView.contentOffset.y - self.tableView.contentInset.top, self.headerMinHeight))
		self.headerViewController?.view.frame = rect//self.view.convert(rect, to:self.tableView)
		self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0)

	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(true, animated: animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if transitionCoordinator?.viewController(forKey: .to)?.parent == navigationController {
			self.navigationController?.setNavigationBarHidden(false, animated: animated)
		}
	}
	
	override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
		super.willTransition(to: newCollection, with: coordinator)
		DispatchQueue.main.async {
			if let headerViewController = self.headerViewController {
				self.headerMinHeight = headerViewController.view.systemLayoutSizeFitting(CGSize(width:self.view.bounds.size.width, height:0), withHorizontalFittingPriority:UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityDefaultHigh).height
				self.headerMaxHeight = headerViewController.view.systemLayoutSizeFitting(CGSize(width:self.view.bounds.size.width, height:0), withHorizontalFittingPriority:UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel).height
				var rect = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.bounds.size.width, height: self.headerMaxHeight))
				self.tableView?.tableHeaderView?.frame = rect
				
				rect = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: max(self.headerMaxHeight - self.tableView.contentOffset.y, self.headerMinHeight))
				headerViewController.view.frame = self.view.convert(rect, to:self.tableView)
				self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0)
			}

		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		let account = NCAccount.current
		
		var sections = [
			DefaultTreeSection(nodeIdentifier: "Character", title: NSLocalizedString("Character", comment: "").uppercased(),
			                   children: [
								NCCharacterSheetMenuRow(nodeIdentifier: "CharacterSheet",
								                        image: #imageLiteral(resourceName: "charactersheet"),
								                        title: NSLocalizedString("Character Sheet", comment: ""),
								                        route: Router.MainMenu.CharacterSheet(),
								                        scopes: [.esiWalletReadCharacterWalletV1,
								                                 .esiSkillsReadSkillsV1,
								                                 .esiLocationReadLocationV1,
								                                 .esiLocationReadShipTypeV1,
								                                 .esiClonesReadImplantsV1],
								                        account: account),
								NCJumpClonesMenuRow(nodeIdentifier: "JumpClones",
								                    image: #imageLiteral(resourceName: "jumpclones"),
								                    title: NSLocalizedString("Jump Clones", comment: ""),
								                    route: Router.MainMenu.JumpClones(),
								                    scopes: [.esiClonesReadClonesV1,
								                             .esiClonesReadImplantsV1],
								                    account: account),
								NCSkillsMenuRow(nodeIdentifier: "Skills",
								                image: #imageLiteral(resourceName: "skills"),
								                title: NSLocalizedString("Skills", comment: ""),
								                route: Router.MainMenu.Skills(),
								                scopes: [.esiSkillsReadSkillqueueV1,
								                         .esiSkillsReadSkillsV1,
								                         .esiClonesReadImplantsV1],
								                account: account),
								NCMainMenuRow(nodeIdentifier: "Mail",
								              image: #imageLiteral(resourceName: "evemail"),
								              title: NSLocalizedString("EVE Mail", comment: ""),
								              route: Router.MainMenu.Mail(),
								              scopes: [.esiMailReadMailV1,
								                       .esiMailSendMailV1,
								                       .esiMailOrganizeMailV1],
								              account: account),
								NCMainMenuRow(nodeIdentifier: "Calendar",
								              image: #imageLiteral(resourceName: "calendar"),
								              title: NSLocalizedString("Calendar", comment: ""),
								              route: Router.MainMenu.Calendar(),
								              scopes: [.esiCalendarReadCalendarEventsV1,
								                       .esiCalendarRespondCalendarEventsV1],
								              account: account),
								NCWealthMenuRow(nodeIdentifier: "Wealth",
								                image: #imageLiteral(resourceName: "folder"),
								                title: NSLocalizedString("Wealth", comment: ""),
								                route: Router.MainMenu.Wealth(),
								                scopes: [.esiWalletReadCharacterWalletV1,
								                         .esiAssetsReadAssetsV1],
								                account: account)
								]),

			DefaultTreeSection(nodeIdentifier: "Database", title: NSLocalizedString("Database", comment: "").uppercased(),
		                                   children: [
											NCMainMenuRow(nodeIdentifier: "Database", image: #imageLiteral(resourceName: "items"), title: NSLocalizedString("Database", comment: ""), route: Router.MainMenu.Database()),
											NCMainMenuRow(nodeIdentifier: "Certificates", image: #imageLiteral(resourceName: "certificates"), title: NSLocalizedString("Certificates", comment: ""), route: Router.MainMenu.Certificates()),
											NCMainMenuRow(nodeIdentifier: "Market", image: #imageLiteral(resourceName: "market"), title: NSLocalizedString("Market", comment: ""), route: Router.MainMenu.Market()),
											NCMainMenuRow(nodeIdentifier: "NPC", image: #imageLiteral(resourceName: "criminal"), title: NSLocalizedString("NPC", comment: ""), route: Router.MainMenu.NPC()),
											NCMainMenuRow(nodeIdentifier: "Wormholes", image: #imageLiteral(resourceName: "terminate"), title: NSLocalizedString("Wormholes", comment: ""), route: Router.MainMenu.Wormholes()),
											NCMainMenuRow(nodeIdentifier: "Incursions", image: #imageLiteral(resourceName: "incursions"), title: NSLocalizedString("Incursions", comment: ""), route: Router.MainMenu.Incursions())
				]),
			
			DefaultTreeSection(nodeIdentifier: "Fitting", title: NSLocalizedString("Fitting/Kills", comment: "").uppercased(),
			                   children: [
								NCMainMenuRow(nodeIdentifier: "Fitting", image: #imageLiteral(resourceName: "fitting"), title: NSLocalizedString("Fitting", comment: ""), route: Router.MainMenu.Fitting()),
								NCMainMenuRow(nodeIdentifier: "KillReports",
								              image: #imageLiteral(resourceName: "killreport"),
								              title: NSLocalizedString("Kill Reports", comment: ""),
								              route: Router.MainMenu.KillReports(),
								              scopes: [.esiKillmailsReadKillmailsV1],
								              account: account),
								NCMainMenuRow(nodeIdentifier: "zKillboardReports", image: #imageLiteral(resourceName: "killrights"), title: NSLocalizedString("zKillboard Reports", comment: ""), route: Router.MainMenu.ZKillboardReports())
				]),
			
			DefaultTreeSection(nodeIdentifier: "Business", title: NSLocalizedString("Business", comment: "").uppercased(),
			                   children: [
								NCMainMenuRow(nodeIdentifier: "Assets",
								              image: #imageLiteral(resourceName: "assets"),
								              title: NSLocalizedString("Assets", comment: ""),
								              route: Router.MainMenu.Assets(),
								              scopes: [.esiAssetsReadAssetsV1],
								              account: account),
								NCMainMenuRow(nodeIdentifier: "MarketOrders",
								              image: #imageLiteral(resourceName: "marketdeliveries"),
								              title: NSLocalizedString("Market Orders", comment: ""),
								              route: Router.MainMenu.MarketOrders(),
								              scopes: [.esiMarketsReadCharacterOrdersV1],
								              account: account),
								NCMainMenuRow(nodeIdentifier: "Contracts",
								              image: #imageLiteral(resourceName: "contracts"),
								              title: NSLocalizedString("Contracts", comment: ""),
								              route: Router.MainMenu.Contracts(),
								              scopes: [.esiContractsReadCharacterContractsV1],
								              account: account),
								NCMainMenuRow(nodeIdentifier: "WalletTransactions",
								              image: #imageLiteral(resourceName: "journal"),
								              title: NSLocalizedString("Wallet Transactions", comment: ""),
								              route: Router.MainMenu.WalletTransactions(),
								              scopes: [.characterWalletRead],
								              account: account),
								NCMainMenuRow(nodeIdentifier: "WalletJournal",
								              image: #imageLiteral(resourceName: "wallet"),
								              title: NSLocalizedString("Wallet Journal", comment: ""),
								              route: Router.MainMenu.WalletJournal(),
								              scopes: [.characterWalletRead],
								              account: account),
								NCMainMenuRow(nodeIdentifier: "IndustryJobs",
								              image: #imageLiteral(resourceName: "industry"),
								              title: NSLocalizedString("Industry Jobs", comment: ""),
								              route: Router.MainMenu.IndustryJobs(),
								              scopes: [.esiIndustryReadCharacterJobsV1],
								              account: account),
								NCMainMenuRow(nodeIdentifier: "Planetaries",
								              image: #imageLiteral(resourceName: "planets"),
								              title: NSLocalizedString("Planetaries", comment: ""),
								              route: Router.MainMenu.Planetaries(),
								              scopes: [.esiPlanetsManagePlanetsV1],
								              account: account),
				]),

			DefaultTreeSection(nodeIdentifier: "Info", title: NSLocalizedString("Info", comment: "").uppercased(),
			                   children: [
								NCMainMenuRow(nodeIdentifier: "News", image: #imageLiteral(resourceName: "newspost"), title: NSLocalizedString("News", comment: ""), route: Router.MainMenu.News()),
								NCMainMenuRow(nodeIdentifier: "Settings", image: #imageLiteral(resourceName: "settings"), title: NSLocalizedString("Settings", comment: ""), route: Router.MainMenu.Settings())
				])


		]
		
//		let currentScopes = Set((account?.scopes?.allObjects as? [NCScope])?.flatMap {return $0.name != nil ? ESI.Scope($0.name!) : nil} ?? [])
		
		sections.forEach {$0.children = ($0.children as! [NCMainMenuRow]).filter({$0.scopes.isEmpty || account != nil})}
		sections = sections.filter {!$0.children.isEmpty}
		
		treeController?.content = RootNode(sections, collapseIdentifier: "NCMainMenuViewController")
		
		tableView.layoutIfNeeded()
		updateHeader()

		completionHandler()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCAccountsViewController" {
			segue.destination.transitioningDelegate = self
		}
	}
	
	/*//MARK: UITableViewDataSource
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return self.mainMenu.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.mainMenu[section].count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NCDefaultTableViewCell
		let row = self.mainMenu[indexPath.section][indexPath.row]
		
		let isEnabled: Bool = {
			guard let scopes = row["scopes"] as? [String] else {return true}
			guard let currentScopes = currentScopes else {return false}
			return Set(scopes).isSubset(of: currentScopes)
		}()

		
		cell.titleLabel?.text = row["title"] as? String
		if let image = row["image"] as? String {
			cell.iconView?.image = UIImage.init(named: image)
		}
		
		if isEnabled {
			if let detailsKeyPath = row["detailsKeyPath"] as? String, let mainMenuDetails = self.mainMenuDetails {
				cell.binder.bind("subtitleLabel.text", toObject: mainMenuDetails, withKeyPath: detailsKeyPath, transformer: nil)
			}
			else {
				cell.subtitleLabel?.text = nil
			}
			cell.titleLabel?.textColor = UIColor.white
		}
		else {
			cell.titleLabel?.textColor = UIColor.lightText
			cell.subtitleLabel?.text = NSLocalizedString("Please sign in again to unlock all features", comment: "")
		}
		
		return cell
	}
	
	func currentAccountChanged(_ note: Notification) {
		loadMenu()
		tableView.reloadData()
		tableView.layoutIfNeeded()
		updateHeader()
	}*/
	
	func managedObjectContextDidSave(_ note: Notification) {
		guard NCAccount.current == nil else {return}
		guard let viewContext = NCStorage.sharedStorage?.viewContext, let context = note.object as? NSManagedObjectContext else {return}
		guard context.persistentStoreCoordinator === viewContext.persistentStoreCoordinator else {return}
		
		if (note.userInfo?[NSDeletedObjectsKey] as? NSSet)?.contains(where: {$0 is NCAccount}) == true ||
			(note.userInfo?[NSInsertedObjectsKey] as? NSSet)?.contains(where: {$0 is NCAccount}) == true {
			DispatchQueue.main.async {
				self.updateHeader()
			}
		}
	}
	/*
	//MARK: UIScrollViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let row = self.mainMenu[indexPath.section][indexPath.row]
		
		let isEnabled: Bool = {
			guard let scopes = row["scopes"] as? [String] else {return true}
			guard let currentScopes = currentScopes else {return false}
			return Set(scopes).isSubset(of: currentScopes)
		}()

		if isEnabled {
			if let segue = row["segueIdentifier"] as? String {
				performSegue(withIdentifier: segue, sender: tableView.cellForRow(at: indexPath))
			}
		}
		else {
			let url = OAuth2.authURL(clientID: ESClientID, callbackURL: ESCallbackURL, scope: ESI.Scope.default, state: "esi")
			if #available(iOS 10.0, *) {
				UIApplication.shared.open(url, options: [:], completionHandler: nil)
			} else {
				UIApplication.shared.openURL(url)
			}
		}
	}*/
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//		let rect = CGRect(x: 0, y: self.topLayoutGuide.length + self.tableView.contentOffset.y, width: self.view.bounds.size.width, height: max(self.headerMaxHeight - self.tableView.contentOffset.y, self.headerMinHeight))
//
//		self.headerViewController?.view.frame = rect//self.view.convert(rect, to:self.tableView)
//		self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0)
		if (scrollView.contentOffset.y < -70 && self.transitionCoordinator == nil && scrollView.isTracking) {
			self.isInteractive = true
			self.performSegue(withIdentifier: "NCAccountsViewController", sender: self)
			self.isInteractive = false;
		}
	}
	
	//MARK: UIViewControllerTransitioningDelegate
	
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return NCSlideDownAnimationController()
	}
	
	func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return isInteractive ? NCSlideDownInteractiveTransition(scrollView: self.tableView) : nil
	}
	
	//MARK: Private
	
	private func updateHeader() {
		let identifier: String
		if NCAccount.current != nil {
			identifier = "NCMainMenuCharacterHeaderViewController"
		}
		else {
			identifier = (try? NCStorage.sharedStorage!.viewContext.count(for: NSFetchRequest<NCAccount>(entityName: "Account"))) ?? 0 > 0 ? "NCMainMenuLoginHeaderViewController" : "NCMainMenuHeaderViewController"
		}
		
		let from = self.headerViewController
		let to = self.storyboard!.instantiateViewController(withIdentifier: identifier) as! NCMainMenuHeaderViewController
		
		headerMinHeight = to.view.systemLayoutSizeFitting(CGSize(width:self.view.bounds.size.width, height:0), withHorizontalFittingPriority:UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityDefaultHigh).height
		headerMaxHeight = to.view.systemLayoutSizeFitting(CGSize(width:self.view.bounds.size.width, height:0), withHorizontalFittingPriority:UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel).height
		
		let rect = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.bounds.size.width, height: self.headerMaxHeight))

		to.view.frame = rect
		to.view.translatesAutoresizingMaskIntoConstraints = true
		to.view.layoutIfNeeded()
		
		
		if let from = from {
			from.willMove(toParentViewController: nil)
			addChildViewController(to)
			to.view.alpha = 0.0;
			transition(from: from, to: to, duration: 0.25, options: [], animations: { 
				from.view.alpha = 0.0;
				to.view.alpha = 1.0;
				self.tableView?.tableHeaderView?.frame = rect;
				self.tableView?.tableHeaderView = self.tableView?.tableHeaderView;
			}, completion: { (fihisned) in
				from.removeFromParentViewController()
				to.didMove(toParentViewController: self)
			})
		}
		else {
			self.tableView?.tableHeaderView?.frame = rect;
			self.tableView?.tableHeaderView = self.tableView?.tableHeaderView;
			addChildViewController(to)
			self.tableView.addSubview(to.view)
			to.didMove(toParentViewController: self)
		}
		
		self.headerViewController = to;
	}
	
	var currentScopes: Set<String>?
	
	private func loadMenu() {
		currentScopes = Set<String>((NCAccount.current?.scopes as? Set<NCScope>)?.flatMap { return $0.name} ?? [])
		
		let mainMenu = NSArray.init(contentsOf: Bundle.main.url(forResource: "mainMenu", withExtension: "plist")!) as! [[[String: Any]]]
		
		if currentScopes!.isEmpty {
			var sections = [[[String: Any]]]()

			for section in mainMenu {
				let rows = section.filter { ($0["scopes"] as? [String] ?? []).isEmpty }
				if !rows.isEmpty {
					sections.append(rows)
				}
			}
			self.mainMenu = sections
		}
		else {
			var sections = [[[String: Any]]]()
			
			for section in mainMenu {
				let rows = section.filter { ($0["scopes"] as? [String])?.first != "n/a" }
				if !rows.isEmpty {
					sections.append(rows)
				}
			}
			self.mainMenu = sections
		}
		
		updateAccountInfo()
	}
	
	private func updateAccountInfo() {
		if let account = NCAccount.current {
			let mainMenuDetails = NCMainMenuDetails(account: account)
			self.mainMenuDetails = mainMenuDetails
			let dataManager = NCDataManager(account: account)
			
			dataManager.skills { result in
				switch result {
				case let .success(_, cacheRecord):
					mainMenuDetails.skillsRecord = cacheRecord
				default:
					break
				}
			}

			dataManager.skillQueue { result in
				switch result {
				case let .success(_, cacheRecord):
					mainMenuDetails.skillQueueRecord = cacheRecord
				default:
					break
				}
			}

			dataManager.clones { result in
				switch result {
				case let .success(_, cacheRecord):
					mainMenuDetails.clonesRecord = cacheRecord
				default:
					break
				}
			}
			
			dataManager.walletBalance { result in
				switch result {
				case let .success(_, cacheRecord):
					mainMenuDetails.walletBalanceRecord = cacheRecord
				default:
					break
				}
			}
			
		}
		else {
			self.mainMenuDetails = nil
		}
	}

}
