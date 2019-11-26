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
    @State private var showCancelButton: Bool = false
    
//    init(text: Binding<String>) {
//        _search = ObservedObject(initialValue: Search(text))
//    }
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")

                TextField("search", text: $text, onEditingChanged: { isEditing in
                    withAnimation {
                        self.showCancelButton = true
                    }
                }, onCommit: {
                    print("onCommit")
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

            if showCancelButton  {
                Button("Cancel") {
                    withAnimation {
                        UIApplication.shared.endEditing(true)
                        self.text = ""
                        self.showCancelButton = false
                    }
                }
                .foregroundColor(Color(.systemBlue))
                .transition(.move(edge: .trailing))
            }
        }
        .padding(.horizontal)
        .navigationBarHidden(showCancelButton)
    }
}

struct SearchField_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchField(text: .constant(""))
                .navigationBarTitle("Title")
        }
    }
}
