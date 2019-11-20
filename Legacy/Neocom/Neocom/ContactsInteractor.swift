//
//  ContactsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/20/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData

class ContactsInteractor: TreeInteractor {
	typealias Presenter = ContactsPresenter
	typealias Content = Void
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
}
