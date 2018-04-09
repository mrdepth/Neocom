//
//  NCDatabaseCertificateMasteryViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI


class NCDatabaseCertificateMasteryViewController: NCTreeViewController {
	var certificate: NCDBCertCertificate?
	var headerViewController: NCDatabaseCertificateInfoHeaderViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCActionHeaderTableViewCell.default,
		                    ])
		
		if let certificate = certificate {
			let headerViewController = self.storyboard!.instantiateViewController(withIdentifier: "NCDatabaseCertificateInfoHeaderViewController") as! NCDatabaseCertificateInfoHeaderViewController
			headerViewController.certificate = certificate
			
			var frame = CGRect.zero
			frame.size = headerViewController.view.systemLayoutSizeFitting(CGSize(width: view.bounds.size.width, height:0), withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel)
			headerViewController.view.frame = frame
			tableView.tableHeaderView = UIView(frame: frame)
			tableView.addSubview(headerViewController.view)
			addChildViewController(headerViewController)
			self.headerViewController = headerViewController
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		if let headerViewController = headerViewController {
			DispatchQueue.main.async {
				var frame = CGRect.zero
				frame.size = headerViewController.view.systemLayoutSizeFitting(CGSize(width: size.width, height:0), withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel)
				headerViewController.view.frame = frame
				self.tableView.tableHeaderView?.frame = frame
				self.tableView.tableHeaderView = self.tableView.tableHeaderView
			}
		}
	}
	
	override func content() -> Future<TreeNode?> {
		guard let certificate = certificate else {return .init(nil)}
		let progress = Progress(totalUnitCount: 1)
		return NCDatabase.sharedDatabase!.performBackgroundTask { managedObjectContext -> TreeNode? in
			let character = (try? progress.perform{ NCCharacter.load(account: NCAccount.current) }.get()) ?? NCCharacter()
			let certificate = try! managedObjectContext.existingObject(with: certificate.objectID) as! NCDBCertCertificate
			var masteries = [TreeSection]()
			for mastery in (certificate.masteries?.sortedArray(using: [NSSortDescriptor(key: "level.level", ascending: true)]) as? [NCDBCertMastery]) ?? [] {
				var rows = [NCDatabaseTypeSkillRow]()
				for skill in mastery.skills?.sortedArray(using: [NSSortDescriptor(key: "type.typeName", ascending: true)]) as? [NCDBCertSkill] ?? [] {
					let row = NCDatabaseTypeSkillRow(skill: skill, character: character)
					rows.append(row)
				}
				let trainingQueue = NCTrainingQueue(character: character)
				trainingQueue.add(mastery: mastery)
				let title = NSLocalizedString("Level", comment: "").uppercased() + " \(String(romanNumber: Int(mastery.level!.level + 1)))"
				let section = NCDatabaseSkillsSection(nodeIdentifier: nil, title: title, trainingQueue: trainingQueue, character: character, children: rows)
				section.isExpanded = section.trainingTime > 0
				masteries.append(section)
			}
			
			guard !masteries.isEmpty else {throw NCTreeViewControllerError.noResult}
			return RootNode(masteries)
		}
	}
	
	// MARK: TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		if let item = node as? NCDatabaseSkillsSection {
			performTraining(trainingQueue: item.trainingQueue, character: item.character, sender: treeController.cell(for: node))
		}
	}
	

	// MARK: Private
	
	private func performTraining(trainingQueue: NCTrainingQueue, character: NCCharacter, sender: UITableViewCell?) {
		guard let account = NCAccount.current else {return}
		
		let message = String(format: NSLocalizedString("Total Training Time: %@", comment: ""), NCTimeIntervalFormatter.localizedString(from: trainingQueue.trainingTime(characterAttributes: character.attributes), precision: .seconds))
		
		let controller = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Add to Skill Plan", comment: ""), style: .default) { [weak self] _ in
			account.activeSkillPlan?.add(trainingQueue: trainingQueue)
			
			if account.managedObjectContext?.hasChanges == true {
				try? account.managedObjectContext?.save()
				self?.tableView.reloadData()
			}
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
		present(controller, animated: true)
		controller.popoverPresentationController?.sourceView = sender
		controller.popoverPresentationController?.sourceRect = sender?.bounds ?? .zero
	}
	
}
