//
//  MainMenuViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

class MainMenuViewController: TreeViewController<MainMenuPresenter>, TreeView {
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(true, animated: animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if transitionCoordinator?.viewController(forKey: .to)?.parent == navigationController {
			self.navigationController?.setNavigationBarHidden(false, animated: animated)
		}
	}
}
