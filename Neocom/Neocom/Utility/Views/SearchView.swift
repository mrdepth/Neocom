//
//  SearchView.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/27/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

struct SearchView<Results: Publisher, Content: View>: View where Results.Failure == Never {
    @ObservedObject var searchResults: SearchResults<Results.Output>
    @State var isEditing: Bool = false
    
    var content: (Results.Output?) -> Content
    
    init(initialValue: Results.Output, action: @escaping (String) -> Results, @ViewBuilder content: @escaping (Results.Output?) -> Content) {
        self.content = content
        searchResults = SearchResults(initialValue: initialValue, action)
    }
        
        
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                SearchField(text: $searchResults.searchString, isEditing: $isEditing)
                content(searchResults.searchString.isEmpty ? nil : searchResults.results)
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchView(initialValue: "", action: { string in
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
