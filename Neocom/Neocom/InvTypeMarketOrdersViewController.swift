//
//  InvTypeMarketOrdersViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/26/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

enum InvTypeMarketOrdersViewControllerInput {
	case typeID(Int)
}

class InvTypeMarketOrdersViewController: TreeViewController<InvTypeMarketOrdersPresenter, InvTypeMarketOrdersViewControllerInput>, TreeView {
	
	@IBAction func onRegions(_ sender: Any) {
		presenter.onRegions(sender)
	}
}

