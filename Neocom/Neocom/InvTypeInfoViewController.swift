//
//  InvTypeInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import TreeController

class InvTypeInfoViewController: TreeViewController<InvTypeInfoPresenter, InvTypeInfoViewController.Input>, TreeView {
	enum Input {
		case type(SDEInvType)
		case typeID(Int)
		case objectID(NSManagedObjectID)
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}
}

