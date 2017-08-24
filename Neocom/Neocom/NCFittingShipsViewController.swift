//
//  NCFittingShipsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import CloudData
import EVEAPI

class NCFittingShipsViewController: NCFittingLoadoutsViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		var sections = [TreeNode]()
		
		sections.append(DefaultTreeRow(image: #imageLiteral(resourceName: "fitting"), title: NSLocalizedString("New Ship Fit", comment: ""), accessoryType: .disclosureIndicator, route: Router.Database.TypePicker(category: NCDBDgmppItemCategory.category(categoryID: .ship)!, completionHandler: {[weak self] (controller, type) in
			guard let strongSelf = self else {return}
			strongSelf.dismiss(animated: true)
			
			Router.Fitting.Editor(typeID: Int(type.typeID)).perform(source: strongSelf, sender: nil)
			
		})))
		
		sections.append(DefaultTreeRow(image: #imageLiteral(resourceName: "browser"), title: NSLocalizedString("Import/Export", comment: ""), accessoryType: .disclosureIndicator, route: Router.Fitting.Server()))
		
		sections.append(NCLoadoutsSection(categoryID: .ship))
		self.treeController?.content = RootNode(sections)
		completionHandler()
	}
	
}
