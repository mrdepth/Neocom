//
//  SearchManager.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class SearchManager<Presenter: ContentProviderPresenter> {
	private var searchString: String?
	
	weak var presenter: Presenter?
	init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func pop() -> String? {
		defer {
			searchString = nil
		}
		return searchString
	}
	
	func updateSearchResults(with string: String) {
		if searchString == nil {
			searchString = string
			if let loading = presenter?.loading {
				loading.then(on: .main) { [weak presenter] _ in
					DispatchQueue.main.async {
						presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) {
							presenter?.view?.present($0, animated: false)
						}
					}
				}
			}
			else {
				presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak presenter] in
					presenter?.view?.present($0, animated: false)
				}
			}
		}
		else {
			searchString = string
		}
	}
}
