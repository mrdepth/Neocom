//
//  NCTypePickerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCTypePickerViewController: NCNavigationController {
	private var isChanged: Bool = true
	var category: NCDBDgmppItemCategory? {
		didSet {
			if oldValue !== category {
				guard let category = category else {return}
				guard let group: NCDBDgmppItemGroup = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category) else {return}
				if (group.items?.count ?? 0) > 0 {
					guard let controller = storyboard?.instantiateViewController(withIdentifier: "NCTypePickerContainerViewContrller") as? NCTypePickerContainerViewContrller else {return}
//					controller.predicate = NSPredicate(format: "dgmppItem.groups CONTAINS %@ AND published == YES", group)
					controller.predicate = NSPredicate(format: "dgmppItem.groups CONTAINS %@", group)
					controller.title = group.groupName
					viewControllers = [controller]
					
				}
				else {
					guard let controller = storyboard?.instantiateViewController(withIdentifier: "NCTypePickerContainerViewContrller") as? NCTypePickerContainerViewContrller else {return}
					controller.group = group
//					controller.loadViewIfNeeded()
					viewControllers = [controller]
					//let groupsViewController = self.groupsViewController
					//self.viewControllers.first?.title = groupsViewController?.group?.groupName
				}
//				viewControllers.first?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: self, action: #selector(dismissAnimated(_:)))
			}
		}
	}
	
	var type: NCDBInvType?
	var completionHandler: ((NCTypePickerViewController, NCDBInvType) -> Void)!
//	var groupsViewController: NCTypePickerGroupsViewController? {
//		return self.viewControllers.first?.childViewControllers.first(where: {return $0 is NCTypePickerGroupsViewController}) as? NCTypePickerGroupsViewController
//	}

	private var results: NSFetchedResultsController<NSDictionary>?
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		/*guard isChanged else {return}
		isChanged = false
		
		if let category = category, let group: NCDBDgmppItemGroup = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category) {
			if (group.items?.count ?? 0) > 0 {
				guard let controller = storyboard?.instantiateViewController(withIdentifier: "NCTypePickerTypesViewController") as? NCTypePickerTypesViewController else {return}
				controller.predicate = NSPredicate(format: "dgmppItem.groups CONTAINS %@ AND published == YES", group)
				controller.title = group.groupName
				viewControllers = [controller]
				
			}
			else {
				guard let controller = storyboard?.instantiateViewController(withIdentifier: "NCTypePickerRootViewController") else {return}
				viewControllers = [controller]
				let groupsViewController = self.groupsViewController
				groupsViewController?.group = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category)
				self.viewControllers.first?.title = groupsViewController?.group?.groupName
			}
		}*/
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
}
