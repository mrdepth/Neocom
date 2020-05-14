//
//  SearchControllerWrapper.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/2/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

class SearchResultsControllerWrapper<Content: View>: UIHostingController<Content> {
    override var navigationController: UINavigationController? {
        presentingViewController?.navigationController
    }
}

class SearchControllerWrapper<Results, Content: View, P: Publisher>: UIViewController, UISearchResultsUpdating where P.Failure == Never, P.Output == Results {
    var search: (String) -> P
    var content: (Results?) -> Content
    var searchResults: UIHostingController<Content>
    var searchController: UISearchController
    private var subscription: AnyCancellable?
    
    init(search: @escaping (String) -> P, content: @escaping (Results?) -> Content) {
        self.search = search
        self.content = content
        searchResults = SearchResultsControllerWrapper(rootView: content(nil))
        searchController = UISearchController(searchResultsController: searchResults)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    @Published private var searchString: String = ""

    override func didMove(toParent parent: UIViewController?) {
        guard let parent = parent else {return}
        parent.definesPresentationContext = true
        parent.navigationItem.searchController = searchController
        
        
        subscription = $searchString.debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .flatMap {[search] in search($0)}
            .receive(on: RunLoop.main)
            .map{[content] in content($0)}
            .sink { [searchResults] results in
                searchResults.rootView = results
        }
        
        searchController.searchResultsUpdater = self
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        searchString = searchController.searchBar.searchTextField.text ?? ""
    }
}
