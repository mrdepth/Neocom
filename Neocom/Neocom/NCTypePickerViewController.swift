//
//  NCTypePickerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCTypePickerViewController: UINavigationController {
	var category: NCDBDgmppItemCategory?/* {
		didSet {
			guard let category = category else {return}
			guard oldValue !== category else {return}
			guard let group: NCDBDgmppItemGroup = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category) else {return}
			if (group.items?.count ?? 0) > 0 {
				viewControllers = []
			}
			else {
			}
		}
	}*/
	
	var type: NCDBInvType?
	var completionHandler: ((NCDBInvType) -> Void)!
	lazy var groupsViewController: NCTypePickerGroupsViewController? = {
		return self.viewControllers.first?.childViewControllers.first(where: {return $0 is NCTypePickerGroupsViewController}) as? NCTypePickerGroupsViewController
	}()

	private var results: NSFetchedResultsController<NSDictionary>?
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let category = category, let groupsViewController = self.groupsViewController {
			groupsViewController.group = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category)
			self.viewControllers.first?.title = groupsViewController.group?.groupName
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
}
