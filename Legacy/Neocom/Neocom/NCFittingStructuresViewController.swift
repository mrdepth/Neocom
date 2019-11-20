//
//  NCFittingStructuresViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import CloudData
import EVEAPI

class NCFittingStructuresViewController: NCFittingLoadoutsViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func content() -> Future<TreeNode?> {
		var sections = [TreeNode]()
		
		sections.append(DefaultTreeRow(image: #imageLiteral(resourceName: "station"), title: NSLocalizedString("New Structure Fit", comment: ""), accessoryType: .disclosureIndicator, route: Router.Database.TypePicker(category: NCDBDgmppItemCategory.category(categoryID: .structure)!, completionHandler: {[weak self] (controller, type) in
			guard let strongSelf = self else {return}
			strongSelf.dismiss(animated: true)
			
			Router.Fitting.Editor(typeID: Int(type.typeID)).perform(source: strongSelf, sender: nil)

		})))
		
		sections.append(NCLoadoutsSection(categoryID: .structure))
		return .init(RootNode(sections))
	}
	
}
