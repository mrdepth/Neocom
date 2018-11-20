//
//  ContactsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/20/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class ContactsViewController: TreeViewController<ContactsPresenter, ContactsViewController.Input>, TreeView, SearchableViewController {
	struct Input {
		var completion: (ContactsViewController, Contact) -> Void
	}
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		return try! ContactsSearchResults.default.instantiate(self).get()
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}
}

extension ContactsViewController: ContactsSearchResultsViewControllerDelegate {
	func contactsSearchResultsViewController(_ controller: ContactsSearchResultsViewController, didSelect contact: Contact) {
		presenter.didSelectContact(contact)
	}
}
