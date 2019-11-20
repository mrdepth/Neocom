//
//  UIViewController+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

extension UIViewController {
	@IBAction func dismissAnimated(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
}
