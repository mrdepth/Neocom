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

enum InvTypeRequiredForViewControllerInput {
	case objectID(NSManagedObjectID)
}

class InvTypeRequiredForViewController: TreeViewController<InvTypeRequiredForPresenter, InvTypeRequiredForViewControllerInput>, TreeView {
}
