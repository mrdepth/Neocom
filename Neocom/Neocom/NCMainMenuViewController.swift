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
	let account: NCAccount?
	var binder: NCBinder!
	dynamic var skillPoints: String?
	dynamic var skillQueueInfo: String?
	dynamic var unreadMails: String?
	dynamic var balance: String?
	dynamic var jumpClones: String?

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
		self.binder = NCBinder(target: self)
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
		NotificationCenter.default.addObserver(self, selector: #selector(currentAccountChanged(_:)), name: NSNotification.Name.NCCurrentAccountChanged, object: nil)
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
	
	func currentAccountChanged(_ note: Notification) {
		loadMenu()
		tableView.reloadData()
		tableView.layoutIfNeeded()
		updateHeader()
	}
	
	//MARK: UIScrollViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let row = self.mainMenu[indexPath.section][indexPath.row]
		if let segue = row["segueIdentifier"] as? String {
			performSegue(withIdentifier: segue, sender: tableView.cellForRow(at: indexPath))
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
		if let account = NCAccount.currentAccount {
			//identifier = account.eveAPIKey.corporate ? "NCMainMenuCorporationHeaderViewController" : "NCMainMenuCharacterHeaderViewController"
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
	
	private func loadMenu() {
		/*let corporate: Bool
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
				if let accessMask = row[accessMaskKey] as? Int64, accessMask & apiKeyAccessMask == accessMask {
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
		
		self.mainMenu = sections*/
	}

}
