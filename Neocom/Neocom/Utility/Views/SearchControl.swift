//
//  SearchControl.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/4/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

struct SearchControl<SearchResults, PublisherType: Publisher>: UIViewRepresentable where PublisherType.Output == SearchResults, PublisherType.Failure == Never {
    @Binding var text: String
    @Binding var results: SearchResults
    @Binding var isEditing: Bool
    var search: (String) -> PublisherType


    
    func makeCoordinator() -> SearchControlCoordinator<SearchResults, PublisherType> {
        SearchControlCoordinator(text: $text, results: $results, isEditing: $isEditing, search: search)
    }

    func makeUIView(context: Context) -> UISearchBar {
        UISearchBar()
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.searchBarStyle = .minimal
        uiView.text = text
        uiView.delegate = context.coordinator
        context.coordinator.text = $text
        context.coordinator.results = $results
        context.coordinator.isEditing = $isEditing
        context.coordinator.search = search
    }
}


struct SearchList<SearchResults, PublisherType: Publisher, Content: View>: View where PublisherType.Output == SearchResults, PublisherType.Failure == Never {
    @Binding var text: String
    @Binding var results: SearchResults
    @Binding var isEditing: Bool
    var search: (String) -> PublisherType
    var content: Content
    var searchControl: SearchControl<SearchResults, PublisherType>
    
    init(text: Binding<String>, results: Binding<SearchResults>, isEditing: Binding<Bool>, search: @escaping (String) -> PublisherType, @ViewBuilder content: () -> Content) {
        _text = text
        _results = results
        _isEditing = isEditing
        self.search = search
        self.content = content()
        
        searchControl = SearchControl(text: text, results: results, isEditing: isEditing, search: search)
    }


    var body: some View {
        VStack {
            List {
                Section(header: searchControl.padding(.horizontal, 8)
                    .listRowInsets(EdgeInsets())
                    .buttonStyle(PlainButtonStyle()).font(.body)) {
                    EmptyView()
                }
                
                content
            }
        }
    }
}

struct SearchControlTest: View {
    @State private var text = ""
    @State private var results: [String] = []
    @State private var isEditing = false
    @State private var b = false
    var body: some View {
        let search = { (s: String) -> Just<[String]> in
//            print(s)
            return Just((0..<1000).map{String($0)}.filter{$0.contains(s)})
        }
        
        return SearchList(text: $text, results: $results, isEditing: $isEditing, search: search) {
            ForEach(results, id: \.self) {
                Text($0)
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text("Root"))
        
    }
}

struct SearchControl_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchControlTest()
        }
    }
}
