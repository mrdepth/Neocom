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

struct ContentView: View {
    @State var b = false
    @ObservedObject var a: A = A()
    var body: some View {
        
        NavigationView {
            Home()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
