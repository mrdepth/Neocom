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
	var category: NCDBDgmppItemCategory?
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
		if let category = category {
			
			self.groupsViewController?.group = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category)
		}
		super.viewWillAppear(animated)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
}
