//
//  NCSplitViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit


class NCSplitViewController: UISplitViewController {
	override public var preferredStatusBarStyle: UIStatusBarStyle {
		get {
			return self.viewControllers[0].preferredStatusBarStyle
		}
	}
}
