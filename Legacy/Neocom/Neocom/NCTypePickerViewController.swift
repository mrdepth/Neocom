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
					controller.predicate = NSPredicate(format: "dgmppItem.groups CONTAINS %@", group)
					controller.title = group.groupName
					viewControllers = [controller]
					
				}
				else {
					guard let controller = storyboard?.instantiateViewController(withIdentifier: "NCTypePickerContainerViewContrller") as? NCTypePickerContainerViewContrller else {return}
					controller.group = group
					viewControllers = [controller]
				}
			}
		}
	}
	
	var type: NCDBInvType?
	var completionHandler: ((NCTypePickerViewController, NCDBInvType) -> Void)!

	private var results: NSFetchedResultsController<NSDictionary>?
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
}
