//
//  SearchView.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/27/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

private class SearchResults<Results>: ObservableObject {
    @Published var results: Results
    @Published var searchString: String = ""
    
    private var subscription: AnyCancellable?
    
    init<P>(initialValue: Results, _ search: @escaping (String) -> P) where P: Publisher, P.Output == Results, P.Failure == Never {
        _results = Published(initialValue: initialValue)
        searchString = ""
        
        subscription = $searchString.debounce(for: .seconds(0.25), scheduler: DispatchQueue.main).flatMap(search).sink { [weak self] in
            self?.results = $0
        }
    }

}

struct SearchView<Results: Publisher, Content: View, Output>: View where Results.Failure == Never, Results.Output == Output? {
    @ObservedObject private var searchResults: SearchResults<Results.Output>
    @State var isEditing: Bool = false
    
    var content: (Results.Output) -> Content
    
    init(initialValue: Results.Output, search: @escaping (String) -> Results, @ViewBuilder content: @escaping (Results.Output) -> Content) {
        self.content = content
        searchResults = SearchResults(initialValue: initialValue, search)
    }
        
        
    var body: some View {
        VStack(spacing: 0) {
            SearchField(text: $searchResults.searchString, isEditing: $isEditing)
            ZStack {
                content(searchResults.results)
                if searchResults.results == nil && isEditing {
                    Color(.systemFill).edgesIgnoringSafeArea(.all).transition(.opacity)
                }
            }
//            content(searchResults.results)//.overlay(Color(.systemFill).opacity(searchResults.results == nil && isEditing ? 1.0 : 0.0).edgesIgnoringSafeArea(.all))
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchView(initialValue: nil, search: { string in
                Just(string)
            }) { results in
                List {
                    if results == nil {
                        ForEach(0..<100) { _ in
                            Text("Item")
                        }
                    }
                    else {
                        Text(results!)
                    }
                }
            }.navigationBarTitle("Title")
        }
    }
}
