//
//  InvTypeMarketOrdersViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/26/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

class InvTypeMarketOrdersViewController: TreeViewController<InvTypeMarketOrdersPresenter, InvTypeMarketOrdersViewController.Input>, TreeView {
	enum Input {
		case typeID(Int)
	}
	
	@IBAction func onRegions(_ sender: Any) {
		presenter.onRegions(sender)
	}
}

