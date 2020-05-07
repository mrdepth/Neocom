//
//  SearchControlCoordinator.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/4/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

class SearchControlCoordinator<SearchResults, PublisherType: Publisher>: NSObject, UISearchBarDelegate where PublisherType.Output == SearchResults, PublisherType.Failure == Never {
    var text: Binding<String>
    var results: Binding<SearchResults>
    var isEditing: Binding<Bool>
    var search: (String) -> PublisherType
    
    private var subject = PassthroughSubject<String, Never>()
    private var subscription: AnyCancellable?
    
    init(text: Binding<String>, results: Binding<SearchResults>, isEditing: Binding<Bool>, search: @escaping (String) -> PublisherType) {
        self.text = text
        self.results = results
        self.isEditing = isEditing
        self.search = search
        super.init()
        
        subscription = subject.debounce(for: 0.25, scheduler: RunLoop.main)
            .flatMap { search($0) }
            .sink { [weak self] in
                self?.results.wrappedValue = $0
                //                    self?.text.wrappedValue = $0
        }
    }
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        isEditing.wrappedValue = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isEditing.wrappedValue = false
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        subject.send("")
        text.wrappedValue = ""
        searchBar.text = ""
        searchBar.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        subject.send(searchText)
        text.wrappedValue = searchText
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
