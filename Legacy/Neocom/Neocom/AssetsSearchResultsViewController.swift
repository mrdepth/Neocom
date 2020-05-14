//
//  AssetsSearchResultsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/8/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

class AssetsSearchResultsViewController: TreeViewController<AssetsSearchResultsPresenter, AssetsPresenter.Presentation>, TreeView, UISearchResultsUpdating, UISearchBarDelegate {
	
	override func didMove(toParent parent: UIViewController?) {
		super.didMove(toParent: parent)
		if let searchController = parent as? UISearchController {
			let toolbar = UIToolbar(frame: .zero)
			toolbar.sizeToFit()
			toolbar.tintColor = UIColor.caption
			toolbar.barTintColor = UIColor.background
			searchController.searchBar.inputAccessoryView = toolbar
			suggestionsToolbar = toolbar
		}
	}
	
	func updateSearchResults(for searchController: UISearchController) {
		presenter.updateSearchResults(with: searchController.searchBar.text ?? "")
	}
	
	
	func present(_ content: [Tree.Item.Section<Tree.Content.Section, Tree.Item.AssetRow>], animated: Bool) -> Future<Void> {
		return treeController.reloadData(content, options: [], with: .none)
	}
	
	var suggestions: [String]? {
		didSet {
			if let suggestionsToolbar = suggestionsToolbar {
				let items = suggestions?.map { UIBarButtonItem(title: $0, style: .plain, target: self, action: #selector(didSelectSuggestion(_:))) }
				items?.enumerated().forEach {$0.element.tag = $0.offset}
				suggestionsToolbar.setItems(items, animated: true)
			}
		}
	}
	
	var suggestionsToolbar: UIToolbar?
	
	@objc func didSelectSuggestion(_ sender: UIBarButtonItem) {
		guard let suggestions = suggestions, sender.tag < suggestions.count else {return}
		if let searchController = parent as? UISearchController {
			searchController.searchBar.text = suggestions[sender.tag]
		}
	}
}

