//
//  NCZKillboardContactsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCZKillboardContactsViewController: NCContactsSearchResultViewController, UISearchBarDelegate {
	
	@IBOutlet weak var searchBar: UISearchBar!

	override func viewDidLoad() {
		super.viewDidLoad()
		searchBar.searchBarStyle = UISearchBarStyle.default
		searchBar.barStyle = UIBarStyle.black
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		searchBar.becomeFirstResponder()
	}

	//MARK: - UISearchBarDelegate
	
	public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		update(searchString: searchText)
	}

}
