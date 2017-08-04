//
//  NCAccountsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI

class NCAccountsNode: FetchedResultsNode<NCAccount> {
	
	init(context: NSManagedObjectContext) {
		
		let request = NSFetchRequest<NCAccount>(entityName: "Account")
		
		request.sortDescriptors = [NSSortDescriptor(key: "folder.name", ascending: true),
		                           NSSortDescriptor(key: "order", ascending: true),
		                           NSSortDescriptor(key: "characterName", ascending: true)]
		
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "folder.name", cacheName: nil)
		super.init(resultsController: results, sectionNode: NCAccountsFolderSection.self, objectNode: NCAccountRow.self)
	}
}

class NCAccountRow: FetchedResultsObjectNode<NCAccount> {
	
	required init(object: NCAccount) {
		super.init(object: object)
		canMove = true
		cellIdentifier = Prototype.NCAccountTableViewCell.default.reuseIdentifier
	}
	
	var character: NCCachedResult<ESI.Character.Information>? {
		didSet {
			if case let .success(_, record)? = character, let object = record {
				observer?.add(managedObject: object)
			}
		}
	}
	
	var corporation: NCCachedResult<ESI.Corporation.Information>? {
		didSet {
			if case let .success(_, record)? = corporation, let object = record {
				observer?.add(managedObject: object)
			}
		}
	}
	
	var skillQueue: NCCachedResult<[ESI.Skills.SkillQueueItem]>? {
		didSet {
			if case let .success(_, record)? = skillQueue, let object = record {
				observer?.add(managedObject: object)
			}
		}
	}
	
	var walletBalance: NCCachedResult<Float>? {
		didSet {
			if case let .success(_, record)? = walletBalance, let object = record {
				observer?.add(managedObject: object)
			}
		}
	}
	
	var skills: NCCachedResult<ESI.Skills.CharacterSkills>? {
		didSet {
			if case let .success(_, record)? = skills, let object = record {
				observer?.add(managedObject: object)
			}
		}
	}
	
	var location: NCCachedResult<ESI.Location.CharacterLocation>? {
		didSet {
			if case let .success(_, record)? = location, let object = record {
				observer?.add(managedObject: object)
			}
		}
	}
	
	var ship: NCCachedResult<ESI.Location.CharacterShip>? {
		didSet {
			if case let .success(_, record)? = ship, let object = record {
				observer?.add(managedObject: object)
			}
		}
	}
	
	var image: NCCachedResult<UIImage>? {
		didSet {
			if case let .success(_, record)? = image, let object = record {
				observer?.add(managedObject: object)
			}
		}
	}
	
	var accountStatus: NCCachedResult<EVE.Account.AccountStatus>? {
		didSet {
			if case let .success(_, record)? = accountStatus, let object = record {
				observer?.add(managedObject: object)
			}
		}
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCAccountTableViewCell else {return}
		
		if character == nil {
			reload()
		}
		
		cell.object = object
		configureImage(cell: cell)
		configureSkills(cell: cell)
		configureWallets(cell: cell)
		configureLocation(cell: cell)
		configureCharacter(cell: cell)
		configureSkillQueue(cell: cell)
		configureCorporation(cell: cell)
//		configureAccountStatus(cell: cell)
	}
	
	func configureCharacter(cell: NCAccountTableViewCell) {
		if let value = character?.value {
			if let scopes = object.scopes?.flatMap({($0 as? NCScope)?.name}), Set(ESI.Scope.default.map{$0.rawValue}) != Set(scopes) {
				cell.characterNameLabel.attributedText = value.name + " (!)" * [NSForegroundColorAttributeName: UIColor.caption, NSFontAttributeName: UIFont.preferredFont(forTextStyle: .subheadline)]
			}
			else {
				cell.characterNameLabel.text = value.name
			}
		}
		else {
			cell.characterNameLabel.text = character?.error?.localizedDescription ?? " "
		}
	}
	
	func configureCorporation(cell: NCAccountTableViewCell) {
		if let value = corporation?.value {
			cell.corporationLabel.text = value.corporationName
		}
		else {
			cell.corporationLabel.text = corporation?.error?.localizedDescription ?? " "
		}
	}
	
	func configureSkillQueue(cell: NCAccountTableViewCell) {
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
				title = NSAttributedString(string: NSLocalizedString("No skills in training", comment: ""), attributes: [NSForegroundColorAttributeName: UIColor.lightText])
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
			
			
			cell.skillLabel.attributedText = title
			cell.trainingTimeLabel.text = trainingTime
			cell.trainingProgressView.progress = trainingProgress
			cell.skillQueueLabel.text = skillQueueText
		}
		else {
			cell.skillLabel.text = skillQueue?.error?.localizedDescription ?? " "
			cell.skillQueueLabel.text = " "
			cell.trainingTimeLabel.text = " "
			cell.trainingProgressView.progress = 0
		}
	}
	
	func configureWallets(cell: NCAccountTableViewCell) {
		if let value = walletBalance?.value {
			let wealth = Double(value)
			cell.wealthLabel.text = NCUnitFormatter.localizedString(from: wealth, unit: .none, style: .short)
		}
		else {
			cell.wealthLabel.text = walletBalance?.error?.localizedDescription ?? " "
		}
	}
	
	func configureSkills(cell: NCAccountTableViewCell) {
		if let value = skills?.value {
			cell.spLabel.text = NCUnitFormatter.localizedString(from: Double(value.totalSP ?? 0), unit: .none, style: .short)
		}
		else {
			cell.spLabel.text = skills?.error?.localizedDescription ?? " "
		}
	}
	
	func configureLocation(cell: NCAccountTableViewCell) {
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
			s.append(NSAttributedString(string: ship, attributes: [NSForegroundColorAttributeName: UIColor.white]))
			s.append(NSAttributedString(string: ", \(location)", attributes: [NSForegroundColorAttributeName: UIColor.lightText]))
			cell.locationLabel.attributedText = s
		}
		else if let location = location {
			let s = NSAttributedString(string: location, attributes: [NSForegroundColorAttributeName: UIColor.lightText])
			cell.locationLabel.attributedText = s
		}
		else if let ship = ship {
			let s = NSAttributedString(string: ship, attributes: [NSForegroundColorAttributeName: UIColor.white])
			cell.locationLabel.attributedText = s
		}
		else {
			cell.locationLabel.text = self.location?.error?.localizedDescription ?? self.ship?.error?.localizedDescription ?? " "
		}
	}
	
	
	func configureImage(cell: NCAccountTableViewCell) {
		if let value = image?.value {
			cell.characterImageView.image = value
		}
		else {
			cell.characterImageView.image = UIImage()
		}
	}
	
	/*func configureAccountStatus(cell: NCAccountTableViewCell) {
		if let value = accountStatus?.value, let paidUntil = value.paidUntil {
			let t = paidUntil.timeIntervalSinceNow
			let s: String = t > 0 ?
				"\(DateFormatter.localizedString(from: paidUntil, dateStyle: .medium, timeStyle: .none)) (\(NCTimeIntervalFormatter.localizedString(from: t, precision: .days)))" :
				NSLocalizedString("expired", comment: "")
			cell.subscriptionLabel.text = s
		}
		else {
			cell.subscriptionLabel.text = accountStatus?.error?.localizedDescription ?? " "
		}
	}*/
	
	private var observer: NCManagedObjectObserver?
	private var isLoading: Bool = false
	func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (()->Void)? = nil) {
		guard !isLoading else {
			completionHandler?()
			return
		}
		
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
//			if case let .success(_, record)? = strongSelf.accountStatus, updated?.contains(record!) == true {
//				strongSelf.configureAccountStatus(cell: cell)
//			}
		}
		
		let dataManager = NCDataManager(account: object, cachePolicy: cachePolicy)
		
		let cell = treeController?.cell(for: self)
		let progress = cell != nil ? NCProgressHandler(view: cell!, totalUnitCount: 4) : nil
		let dispatchGroup = DispatchGroup()
		
		progress?.progress.becomeCurrent(withPendingUnitCount: 1)
		dispatchGroup.enter()
		
		isLoading = true
		
		dataManager.character { result in
			self.character = result
			
			switch result {
			case let .success(value, _):
				progress?.progress.becomeCurrent(withPendingUnitCount: 1)
				dispatchGroup.enter()
				dataManager.corporation(corporationID: Int64(value.corporationID)) { result in
					self.corporation = result
					dispatchGroup.leave()
					
					if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
						self.configureCorporation(cell: cell)
					}

				}
				progress?.progress.resignCurrent()
			case .failure:
				break
			}

			dispatchGroup.leave()
			
			if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
				self.configureCharacter(cell: cell)
			}
			
		}
		progress?.progress.resignCurrent()

		progress?.progress.becomeCurrent(withPendingUnitCount: 1)
		dispatchGroup.enter()
		dataManager.skillQueue { result in
			self.skillQueue = result
			dispatchGroup.leave()
			
			if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
				self.configureSkillQueue(cell: cell)
			}
		}
		progress?.progress.resignCurrent()

		progress?.progress.becomeCurrent(withPendingUnitCount: 1)
		dispatchGroup.enter()
		dataManager.skills { result in
			self.skills = result
			dispatchGroup.leave()
			
			if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
				self.configureSkills(cell: cell)
			}
		}
		progress?.progress.resignCurrent()

		progress?.progress.becomeCurrent(withPendingUnitCount: 1)
		dispatchGroup.enter()
		dataManager.walletBalance { result in
			self.walletBalance = result
			dispatchGroup.leave()
			
			if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
				self.configureWallets(cell: cell)
			}
		}
		progress?.progress.resignCurrent()
		
		
		progress?.progress.becomeCurrent(withPendingUnitCount: 1)
		dispatchGroup.enter()
		dataManager.characterLocation { result in
			self.location = result
			dispatchGroup.leave()
			
			if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
				self.configureLocation(cell: cell)
			}
		}
		progress?.progress.resignCurrent()

		progress?.progress.becomeCurrent(withPendingUnitCount: 1)
		dispatchGroup.enter()
		dataManager.characterShip { result in
			self.ship = result
			dispatchGroup.leave()
			
			if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
				self.configureLocation(cell: cell)
			}
		}
		progress?.progress.resignCurrent()

		progress?.progress.becomeCurrent(withPendingUnitCount: 1)
		dispatchGroup.enter()
		dataManager.image(characterID: object.characterID, dimension: 64) { result in
			self.image = result
			dispatchGroup.leave()
			
			if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
				self.configureImage(cell: cell)
			}
		}
		progress?.progress.resignCurrent()

		/*progress?.progress.becomeCurrent(withPendingUnitCount: 1)
		dispatchGroup.enter()
		dataManager.accountStatus { result in
			self.accountStatus = result
			dispatchGroup.leave()
			
			if let cell = self.treeController?.cell(for: self) as? NCAccountTableViewCell, cell.object as? NCAccount == self.object {
				self.configureAccountStatus(cell: cell)
			}
		}
		progress?.progress.resignCurrent()*/

		dispatchGroup.notify(queue: .main) {
			progress?.finish()
			self.isLoading = false
			completionHandler?()
		}
		
	}
	
}

class NCAccountsFolderSection: FetchedResultsSectionNode<NCAccount> {
	required init(section: NSFetchedResultsSectionInfo, objectNode: FetchedResultsObjectNode<NCAccount>.Type) {
		super.init(section: section, objectNode: objectNode)
		cellIdentifier = Prototype.NCHeaderTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.titleLabel?.text = section.name.isEmpty ? NSLocalizedString("Accounts", comment: "").uppercased() : section.name.uppercased()
	}
}

class NCAccountsViewController: UITableViewController, TreeControllerDelegate, UIViewControllerTransitioningDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.rightBarButtonItem = editButtonItem
		
		registerRefreshable()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCActionTableViewCell.default,
		                    Prototype.NCAccountTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.empty])
		
		treeController.delegate = self
		
		guard let context = NCStorage.sharedStorage?.viewContext else {return}
		
		let row = NCActionRow(title: NSLocalizedString("SIGN IN", comment: ""))
		let space = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty)
		treeController.content = RootNode([NCAccountsNode(context: context), space, row])
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		navigationController?.transitioningDelegate = self
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		guard let context = NCStorage.sharedStorage?.viewContext else {return}
		if context.hasChanges {
			try? context.save()
		}
	}

	
	@IBAction func onDelete(_ sender: Any) {
		let selected = treeController.selectedNodes().flatMap {$0 as? NCAccountRow}
		guard !selected.isEmpty else {return}
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		controller.addAction(UIAlertAction(title: String(format: NSLocalizedString("Delete %d Accounts", comment: ""), selected.count), style: .destructive) { [weak self] _ in
			selected.forEach {
				$0.object.managedObjectContext?.delete($0.object)
			}
			if let context = selected.first?.object.managedObjectContext, context.hasChanges {
				try? context.save()
			}
			self?.updateTitle()
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		
		present(controller, animated: true, completion: nil)
	}
	
	@IBAction func onMoveTo(_ sender: Any) {
		let selected = treeController.selectedNodes().flatMap {$0 as? NCAccountRow}
		guard !selected.isEmpty else {return}

		Router.Account.AccountsFolderPicker { [weak self] (controller, folder) in
			controller.dismiss(animated: true, completion: nil)
			selected.forEach {
				$0.object.folder = folder
			}
			
			if let context = selected.first?.object.managedObjectContext, context.hasChanges {
				try? context.save()
			}
			self?.updateTitle()

		}.perform(source: self)
	}
	
	@IBAction func onClose(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		if !editing {
			guard let context = NCStorage.sharedStorage?.viewContext else {return}
			if context.hasChanges {
				try? context.save()
			}
		}
		navigationController?.setToolbarHidden(!editing, animated: true)
		updateTitle()
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
	
	// MARK: TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if isEditing {
			if !(node is NCAccountRow) {
				treeController.deselectCell(for: node, animated: true)
			}
			updateTitle()
		}
		else {
			treeController.deselectCell(for: node, animated: true)
			if node is NCActionRow {
				let url = OAuth2.authURL(clientID: ESClientID, callbackURL: ESCallbackURL, scope: ESI.Scope.default, state: "esi")
				if #available(iOS 10.0, *) {
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				} else {
					UIApplication.shared.openURL(url)
				}
			}
			else if let node = node as? NCAccountRow {
				NCAccount.current = node.object
				dismiss(animated: true, completion: nil)
			}
		}
	}
	
	func treeController(_ treeController: TreeController, didDeselectCellWithNode node: TreeNode) {
		if isEditing {
			updateTitle()
		}
	}
	
	func treeController(_ treeController: TreeController, didCollapseCellWithNode node: TreeNode) {
		updateTitle()
		
	}
	
	func treeController(_ treeController: TreeController, didExpandCellWithNode node: TreeNode) {
		updateTitle()
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCAccountRow else {return nil}
		return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { [weak self] _ in
			let account = node.object
			account.managedObjectContext?.delete(account)
			try? account.managedObjectContext?.save()
			self?.updateTitle()
		})]
	}
	
	func treeController(_ treeController: TreeController, didMoveNode node: TreeNode, at: Int, to: Int) {
		var order: Int32 = 0
		(node.parent?.children as? [NCAccountRow])?.forEach {
			if $0.object.order != order {
				$0.object.order = order
			}
			order += 1
		}
	}
	
	// MARK: UIViewControllerTransitioningDelegate
	private var isInteractive: Bool = false

	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return NCSlideDownAnimationController()
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return isInteractive ? NCSlideDownInteractiveTransition(scrollView: self.tableView) : nil
	}
	
	//MARK: - NCRefreshable
	
	func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		let progress = NCProgressHandler(viewController: self, totalUnitCount: Int64(treeController.content?.children.count ?? 0))
		let dispatchGroup = DispatchGroup()
		
		for row in treeController.content?.children as? [NCAccountRow] ?? [] {
			dispatchGroup.enter()
			progress.progress.becomeCurrent(withPendingUnitCount: 1)
			row.reload(cachePolicy: cachePolicy) {
				dispatchGroup.leave()
			}
			progress.progress.resignCurrent()
		}
		
		dispatchGroup.notify(queue: .main) {
			progress.finish()
			completionHandler?()
		}
		//		self.dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		//		isEndReached = false
		//		lastID = nil
		//		fetch(from: nil, completionHandler: completionHandler)
	}
	
	//MARK: - Private
	
	private func updateTitle() {
		if isEditing {
			let n = treeController.selectedNodes().count
			title = n > 0 ? String(format: NSLocalizedString("Selected %d Accounts", comment: ""), n) : NSLocalizedString("Accounts", comment: "")
			toolbarItems?.forEach {$0.isEnabled = n > 0}
		}
		else {
			title = NSLocalizedString("Accounts", comment: "")
		}
	}
}
