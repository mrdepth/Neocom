//
//  ContactsSearchResultsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

protocol ContactsSearchResultsViewControllerDelegate {
	func contactsSearchResultsViewController(_ controller: ContactsSearchResultsViewController, didSelect contact: Contact) -> Void
}

class ContactsSearchResultsViewController: TreeViewController<ContactsSearchResultsPresenter, ContactsSearchResultsViewControllerDelegate>, TreeView, UISearchResultsUpdating {
	
	func updateSearchResults(for searchController: UISearchController) {
		presenter.updateSearchResults(with: searchController.searchBar.text ?? "")
	}
	
	func present(_ content: ContactsSearchResultsPresenter.Presentation, animated: Bool) -> Future<Void> {
		tableView.backgroundView = nil
		view.isHidden = content.isEmpty
		return treeController.reloadData(content, with: animated ? .automatic : .none)
	}

	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}
}
