//
//  NCAccountsFolderPickerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCAccountsFolderPickerViewController: NCNavigationController {
	
	var completionHandler: ((NCAccountsFolderPickerViewController, NCAccountsFolder?) -> Void)?
	
}
