//
//  MainPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

class MainPresenter: TreePresenter {
	
	weak var view: MainViewController!
	lazy var interactor: MainInteractor! = MainInteractor(presenter: self)
	
	required init(view: MainViewController) {
		self.view = view
	}

	func presentation(for content: ()) -> Future<[TreeVirtualItem<AnyTreeItem>]> {
		return .init([])
//		TreeContentLeafItem<TreeDefaultItem>(content: TreeDefaultItem(), diffIdentifier: "asdf")
//		TreeContentItem<TreeDefaultItem>(
	}
	
	func applicationWillEnterForeground() {
	}
}


//class MainMenuItem: TreeItemContent<MainMenuItem.Content> {
//	struct Content: TreeItem {
//
//	}
//
//}
