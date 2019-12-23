//
//  ContentView.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

indirect enum E: Identifiable {
    case a(String)
    case b(String, [E])
    
    var id: String {
        switch self {
        case let .a(id):
            return id
        case let .b(id, _):
            return id
        }
    }
    
    var children: [E]? {
        switch self {
        case let .b(_, children):
            return children
        default:
            return nil
        }
    }
}

class A: ObservableObject {
    @Published var t: String
    init() {
        t = Date().description
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.t = Date().description
        }
    }
}

struct Nested: View {
    var b: Bool
    @Environment(\.account) var account
    @ObservedObject var a: A = A()
    
    var body: some View {
        Text(a.t)
    }
}

struct SearchBar: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        return UISearchBar()
    }
    
    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
    }
}

struct ContentView: View {
    @State var b = false
    @ObservedObject var a: A = A()
    
    
    func rows(e: E) -> some View {
        let v = Group {
            Text(e.id)
            e.children.map { a in
                ForEach(a) {
                    self.rows(e: $0)
                }
            }
        }
        return AnyView(v)
    }
	
    var body: some View {
        
        NavigationView {
//			MarketRegionPicker() { _ in }
//            TypeCategories()
            TypeMarketGroup(parent: nil)
//            Home()
//            TypeInfo(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!).environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
