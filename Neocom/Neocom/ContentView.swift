//
//  ContentView.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

class A: ObservableObject {
    @Published var text: String = "Hello World"
    
    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.text = "Updated"
        }
    }
}

struct Child: View {
    var text: String
    
    var body: some View {
        Text(text)
    }
}

struct Root: View {
    @ObservedObject var a = A()
    
    var body: some View {
        NavigationLink(destination: Child(text: a.text)) {
            Text("Next")
        }
    }
}

struct ContentView: View {
    var body: some View {
        
        NavigationView {
//            List {
//                ForEach(0..<2) { _ in
//                    Root()
//                }
//            }
//            TypeMarketGroup(parent: nil)
            CertificateGroups()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
