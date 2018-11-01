//
//  InvTypeRequiredForViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/1/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import CoreData

class InvTypeRequiredForViewController: TreeViewController<InvTypeRequiredForPresenter, InvTypeRequiredForViewController.Input>, TreeView {
	enum Input {
		case objectID(NSManagedObjectID)
	}
}
