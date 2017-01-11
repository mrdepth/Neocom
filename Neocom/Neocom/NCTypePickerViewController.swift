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
	var category: NCDBDgmppItemCategory?
	var type: NCDBInvType?
	var completionHandler: ((NCDBInvType) -> Void)!

	private var results: NSFetchedResultsController<NSDictionary>?
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		if let category = category {
			let controller = self.viewControllers[0] as! NCTypePickerGroupsViewController
			controller.group = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category)
		}
		super.viewWillAppear(animated)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
}
