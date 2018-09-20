//
//  InvCategoriesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class InvCategoriesViewController: TreeViewController<InvCategoriesPresenter, Void>, TreeView {
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		presenter.didSelect(item: item)
	}
}

