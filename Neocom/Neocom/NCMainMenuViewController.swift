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

class NCMainMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate {
	@IBOutlet weak var tableView: NCTableView!
	private weak var headerViewController: NCMainMenuHeaderViewController? = nil
	private var headerMinHeight: CGFloat = 0
	private var headerMaxHeight: CGFloat = 0
	private var mainMenu: [[[String: Any]]] = []
	private var mainMenuDetails: NCMainMenuDetails? = nil
	private var isInteractive: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.estimatedRowHeight = self.tableView.rowHeight
		self.tableView.rowHeight = UITableViewAutomaticDimension
		updateHeader()
		loadMenu()
		NotificationCenter.default.addObserver(self, selector: #selector(currentAccountChanged(_:)), name: .NCCurrentAccountChanged, object: nil)
		if let context = NCStorage.sharedStorage?.viewContext {
			NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: nil)
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let rect = CGRect(x: 0, y: self.topLayoutGuide.length, width: self.view.bounds.size.width, height: max(self.headerMaxHeight - self.tableView.contentOffset.y, self.headerMinHeight))
		self.headerViewController?.view.frame = self.view.convert(rect, to:self.tableView)
		self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0)

	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(true, animated: animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if let toVC = self.transitionCoordinator?.viewController(forKey: UITransitionContextViewControllerKey.to) {
			if toVC === self {
				return
			}
			else if let navigationController = toVC as? UINavigationController {
				if navigationController.topViewController is NCAccountsViewController {
					return
				}
			}
			self.navigationController?.setNavigationBarHidden(false, animated: animated)
		}
		else {
			return
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
				
				rect = CGRect(x: 0, y: self.topLayoutGuide.length, width: self.view.bounds.size.width, height: max(self.headerMaxHeight - self.tableView.contentOffset.y, self.headerMinHeight))
				headerViewController.view.frame = self.view.convert(rect, to:self.tableView)
				self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0)
			}

		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCAccountsViewController" {
			segue.destination.transitioningDelegate = self
		}
	}
	
	//MARK: UITableViewDataSource
	
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
	}
	
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
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let rect = CGRect(x: 0, y: self.topLayoutGuide.length, width: self.view.bounds.size.width, height: max(self.headerMaxHeight - self.tableView.contentOffset.y, self.headerMinHeight))
		self.headerViewController?.view.frame = self.view.convert(rect, to:self.tableView)
		self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(rect.size.height, 0, 0, 0)
		if (scrollView.contentOffset.y < -50 && self.transitionCoordinator == nil && scrollView.isTracking) {
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
