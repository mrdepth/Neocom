//
//  SearchController.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/2/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

struct SearchController<Results, Content: View, P: Publisher>: UIViewControllerRepresentable where P.Failure == Never, P.Output == Results {
    var search: (String) -> P
    var content: (Results?) -> Content
    
    init(search: @escaping (String) -> P, @ViewBuilder content: @escaping (Results?) -> Content) {
        self.search = search
        self.content = content
    }
    
    func makeUIViewController(context: Context) -> SearchControllerWrapper<Results, Content, P> {
        SearchControllerWrapper(search: search, content: content)
    }
    
    func updateUIViewController(_ uiViewController: SearchControllerWrapper<Results, Content, P>, context: Context) {
    }
}

struct SearchControllerTest: View {
    @State private var text: String = "123"
    @State private var isEditing: Bool = false
    @State private var text2: String = "321"
    let subject = CurrentValueSubject<String, Never>("123")
    
    var binding: Binding<String> {
        Binding(get: {
            self.text
        }) {
            self.text = $0
            self.subject.send($0)
        }
    }
    
    var body: some View {
        VStack{
//            SearchBar()
            SearchField(text: binding, isEditing: $isEditing)
            List {
                Text(text2)
            }.onReceive(subject.debounce(for: .seconds(0.25), scheduler: RunLoop.main)) {
                self.text2 = $0
            }
        }
    }
}

struct SearchController_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchControllerTest()
//            VStack {
//                SearchBar()
//                List {
//                    Text("Hello, World")
//                }
//                .listStyle(GroupedListStyle())
////                SearchController(search: {s in
////                    Just(s)
////                }) { results in
////                    NavigationLink(results ?? "", destination: Text("wefwe"))
////                }.disabled(true)
//            }
//            .navigationBarTitle("Root", displayMode: .inline)
        }
    .navigationViewStyle(StackNavigationViewStyle())
    }
}

