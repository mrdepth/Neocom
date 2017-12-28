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

class NCMainMenuRow: DefaultTreeRow {
	let scopes: Set<ESI.Scope>
	let account: NCAccount?
	let isEnabled: Bool
	init(prototype: Prototype = Prototype.NCDefaultTableViewCell.default, nodeIdentifier: String, image: UIImage? = nil, title: String? = nil, route: Route? = nil, scopes: [ESI.Scope] = [], account: NCAccount? = nil) {
		let scopes = Set(scopes)
		self.scopes = scopes
		self.account = account
		let isEnabled: Bool = {
			guard !scopes.isEmpty else {return true}
			guard let currentScopes = account?.scopes?.flatMap({($0 as? NCScope)?.name}).flatMap ({ESI.Scope($0)}) else {return false}
			return scopes.isSubset(of: currentScopes)
		}()
		
		self.isEnabled = isEnabled
		
		super.init(prototype: prototype, nodeIdentifier: nodeIdentifier, image: image, title: title, accessoryType: .disclosureIndicator, route: isEnabled ? route : nil)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = title
		cell.iconView?.image = image
		cell.accessoryType = .disclosureIndicator
		
		if !isEnabled {
			cell.titleLabel?.textColor = .lightText
			cell.subtitleLabel?.text = NSLocalizedString("Please sign in again to unlock all features", comment: "")
		}
		else {
			cell.titleLabel?.textColor = .white
			cell.subtitleLabel?.text = nil
		}
	}
}

class NCAccountDataMenuRow<T>: NCMainMenuRow {
	private var observer: NCManagedObjectObserver?
	var isLoading = false

	var result: NCCachedResult<T>? {
		didSet {
			if let cacheRecord = result?.cacheRecord {
				self.observer = NCManagedObjectObserver(managedObject: cacheRecord) { [weak self] (_,_) in
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
		guard let cell = cell as? NCDefaultTableViewCell, isEnabled else {return}

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
		guard let cell = cell as? NCDefaultTableViewCell, isEnabled else {return}
		
		if let result = result {
			if let value = result.value {
				let t = 3600 * 24 + (value.lastCloneJumpDate ?? .distantPast).timeIntervalSinceNow
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
		guard let cell = cell as? NCDefaultTableViewCell, isEnabled else {return}
		
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

class NCWealthMenuRow: NCAccountDataMenuRow<Double> {
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)

		guard let cell = cell as? NCDefaultTableViewCell, isEnabled else {return}
		
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

class NCServerStatusRow: NCAccountDataMenuRow<ESI.Status.ServerStatus> {
	
	lazy var dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
		dateFormatter.timeStyle = .medium
		dateFormatter.dateStyle = .none
		return dateFormatter
	}()
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell, isEnabled else {return}
		cell.accessoryType = .none
		
		if let result = result {
			if let value = result.value {
				if value.players > 0 {
					cell.titleLabel?.text = String(format: NSLocalizedString("Tranquility: online %@ players", comment: ""), NCUnitFormatter.localizedString(from: value.players, unit: .none, style: .full))
				}
				else {
					cell.titleLabel?.text = NSLocalizedString("Tranquility: offline", comment: "")
				}
				cell.subtitleLabel?.text = NSLocalizedString("EVE Time: ", comment: "") + dateFormatter.string(from: Date())
			}
			else {
				cell.titleLabel?.text = NSLocalizedString("Tranquility", comment: "")
				cell.subtitleLabel?.text = result.error?.localizedDescription
			}
		}
		else {
			cell.titleLabel?.text = NSLocalizedString("Tranquility", comment: "")
			cell.subtitleLabel?.text = NSLocalizedString("Updating...", comment: "")
//			guard !isLoading else {return}
//			isLoading = true
//			NCDataManager(account: NCAccount.current).serverStatus { result in
//				self.result = result
//				self.isLoading = false
//				self.treeController?.reloadCells(for: [self], with: .none)
//			}
		}
		
		if result == nil && !isLoading {
			isLoading = true
			NCDataManager(account: NCAccount.current).serverStatus { result in
				self.result = result
				self.isLoading = false
				self.treeController?.reloadCells(for: [self], with: .none)
				self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerTick(_:)), userInfo: nil, repeats: true)
			}
		}
	}
	
	deinit {
		timer?.invalidate()
	}
	
	private var timer: Timer? {
		didSet {
			oldValue?.invalidate()
		}
	}
	
//	override func willDisplay(cell: UITableViewCell) {
//		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerTick(_:)), userInfo: cell, repeats: true)
//	}
	
	@objc func timerTick(_ timer: Timer) {
		guard let cell = treeController?.cell(for: self) as? NCDefaultTableViewCell else {return}
//		guard let cell = timer.userInfo as? NCDefaultTableViewCell else {return}
		cell.subtitleLabel?.text = NSLocalizedString("EVE Time: ", comment: "") + dateFormatter.string(from: Date())
	}
	
//	override func didEndDisplaying(cell: UITableViewCell) {
//		if (timer?.userInfo as? UITableViewCell) == cell {
//			timer = nil
//		}
//	}
}


class NCMainMenuViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .update
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.noImage])
		
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if let h = tableView.tableHeaderView?.bounds.height {
			self.tableView.scrollIndicatorInsets.top = h
		}
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
	
	/*override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
		super.willTransition(to: newCollection, with: coordinator)
		DispatchQueue.main.async {
			if let headerViewController = self.headerViewController {
				self.headerMinHeight = headerViewController.view.systemLayoutSizeFitting(CGSize(width:self.view.bounds.size.width, height:0), withHorizontalFittingPriority:UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.defaultHigh).height
				self.headerMaxHeight = headerViewController.view.systemLayoutSizeFitting(CGSize(width:self.view.bounds.size.width, height:0), withHorizontalFittingPriority:UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel).height
				var rect = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.bounds.size.width, height: self.headerMaxHeight))
				self.tableView?.tableHeaderView?.frame = rect
				
				rect = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: max(self.headerMaxHeight - self.tableView.contentOffset.y, self.headerMinHeight))
				headerViewController.view.frame = self.view.convert(rect, to:self.tableView)
				self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0)
			}

		}
	}*/
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		let account = NCAccount.current
		
		var sections: [TreeNode] = [
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
								                account: account),
								NCMainMenuRow(nodeIdentifier: "LP",
								                image: #imageLiteral(resourceName: "lpstore"),
								                title: NSLocalizedString("Loyalty Points", comment: ""),
								                route: Router.MainMenu.LoyaltyPoints(),
								                scopes: [.esiCharactersReadLoyaltyV1],
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
								NCMainMenuRow(nodeIdentifier: "Settings", image: #imageLiteral(resourceName: "settings"), title: NSLocalizedString("Settings", comment: ""), route: Router.MainMenu.Settings()),
								NCMainMenuRow(nodeIdentifier: "About", image: #imageLiteral(resourceName: "info"), title: NSLocalizedString("About", comment: ""), route: Router.MainMenu.About())
				])


		]
		
//		let currentScopes = Set((account?.scopes?.allObjects as? [NCScope])?.flatMap {return $0.name != nil ? ESI.Scope($0.name!) : nil} ?? [])
		
		sections.forEach {$0.children = ($0.children as! [NCMainMenuRow]).filter({$0.scopes.isEmpty || account != nil})}
		sections = sections.filter {!$0.children.isEmpty}
		
		sections.insert(NCServerStatusRow(prototype: Prototype.NCDefaultTableViewCell.noImage,nodeIdentifier: "ServerStatus"), at: 0)
		treeController?.content = RootNode(sections, collapseIdentifier: "NCMainMenuViewController")
		
		completionHandler()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCAccountsViewController" {
			segue.destination.transitioningDelegate = parent as? UIViewControllerTransitioningDelegate
		}
	}
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		if (node as? NCMainMenuRow)?.isEnabled == false {
			ESI.performAuthorization(from: self)
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
		let t: CGFloat
		
		if #available(iOS 11, *) {
			t = scrollView.safeAreaInsets.top + 70
		}
		else {
			t = 70
		}
		
		if (scrollView.contentOffset.y < -t && self.transitionCoordinator == nil && scrollView.isTracking) {
//			performSegue(withIdentifier: "NCAccountsViewController", sender: self)
		}
	}

}
