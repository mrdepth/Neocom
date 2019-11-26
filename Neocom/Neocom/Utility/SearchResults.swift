//
//  SearchResults.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/26/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine


class SearchResults<Element>: ObservableObject {
    @Published var results: [Element]
    @Published var searchString: String = ""
    
    private var subscription: AnyCancellable?
    
    init<P>(_ search: @escaping (String) -> P) where P: Publisher, P.Output == [Element], P.Failure == Never {
        _results = Published(initialValue: [])
        searchString = ""
        
        subscription = $searchString.debounce(for: .seconds(0.25), scheduler: DispatchQueue.main).flatMap(search).sink { [weak self] in
            self?.results = $0
        }
    }

}

