//
//  SearchField.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/26/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

private class Search: ObservableObject {
    @Published var searchText: String = ""
    
    private var subscription: AnyCancellable?
    init(_ searchString: Binding<String>) {
        subscription = $searchText.debounce(for: .milliseconds(250), scheduler: DispatchQueue.main).assign(to: \.wrappedValue, on: searchString)
    }
}

struct SearchField: View {
//    @ObservedObject private var search: Search
    @Binding var text: String
    @Binding var isEditing: Bool
    
//    init(text: Binding<String>) {
//        _search = ObservedObject(initialValue: Search(text))
//    }
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")

                TextField("Search", text: $text, onEditingChanged: { isEditing in
                    withAnimation {
                        self.isEditing = isEditing
                    }
                }, onCommit: {
                }).foregroundColor(.primary)

                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill").opacity(text == "" ? 0 : 1)
                }
            }
            .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
            .foregroundColor(.secondary)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10.0)

            if isEditing  {
                Button("Cancel") {
                    withAnimation {
                        UIApplication.shared.endEditing(true)
                        self.text = ""
                        self.isEditing = false
                    }
                }
                .foregroundColor(Color(.systemBlue))
                .transition(.move(edge: .trailing))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
//        .background(Color(.systemBackground))
//        .padding(.horizontal)
//        .navigationBarHidden(isEditing)
    }
}

struct SearchField_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ZStack {
                Color.gray
            SearchField(text: .constant(""), isEditing: .constant(false))
                .navigationBarTitle("Title")
            }
        }
    }
}
