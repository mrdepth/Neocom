//
//  NCAdaptiveSegue.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCAdaptiveSegue: UIStoryboardSegue {
	override func perform() {
		if source.parent is UISearchController {
			source.presentingViewController?.navigationController?.pushViewController(destination, animated: true)
		}
		else {
			if source.presentationController is NCSheetPresentationController || source.navigationController?.presentationController is NCSheetPresentationController {
				let navigationController = NCNavigationController(rootViewController: destination)
				source.present(navigationController, animated: true, completion: nil)
				destination.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: .plain, target: destination, action: #selector(UIViewController.dismissAnimated(_:)))
			}
			else if let navigationController = source.navigationController {
				navigationController.pushViewController(destination, animated: true)
			}
		}
	}
}
