//
//  InvTypeMasteryViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 17/10/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import CoreData

class InvTypeMasteryViewController: TreeViewController<InvTypeMasteryPresenter, InvTypeMasteryViewController.Input>, TreeView {
	struct Input {
		var typeObjectID: NSManagedObjectID
		var masteryLevelObjectID: NSManagedObjectID
	}
}
