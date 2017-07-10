//
//  NCMailAttachmentsShipsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 10.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

class NCAttachmentLoadoutRow: NCLoadoutRow {
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		cell.accessoryType = .detailButton
	}
}

class NCMailAttachmentsShipsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default])
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if treeController.content == nil {
			self.treeController.content = RootNode([NCLoadoutsSection<NCAttachmentLoadoutRow>(categoryID: .ship)])
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let item = node as? NCLoadoutRow else {return}
		guard let context = NCStorage.sharedStorage?.viewContext else {return}
		guard let loadout = (try? context.existingObject(with: item.loadoutID)) else {return}
		guard let parent = parent as? NCMailAttachmentsViewController else {return}
		parent.completionHandler?(parent, loadout)
	}
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		
		if let node = node as? NCLoadoutRow {
			NCStorage.sharedStorage?.performBackgroundTask({ (managedObjectContext) in
				guard let loadout = (try? managedObjectContext.existingObject(with: node.loadoutID)) as? NCLoadout else {return}
				let engine = NCFittingEngine()
				engine.performBlockAndWait {
					let fleet = NCFittingFleet(loadouts: [loadout], engine: engine)
					DispatchQueue.main.async {
						if let account = NCAccount.current {
							fleet.active?.setSkills(from: account) { [weak self]  _ in
								guard let strongSelf = self else {return}
								Router.Fitting.Editor(fleet: fleet, engine: engine).perform(source: strongSelf)
							}
						}
						else {
							fleet.active?.setSkills(level: 5) { [weak self] _ in
								guard let strongSelf = self else {return}
								Router.Fitting.Editor(fleet: fleet, engine: engine).perform(source: strongSelf)
							}
						}
					}
					
				}
			})
		}
	}
	
}
