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
    init(_ s: String) {
        t = s
    }
}

struct Nested: View {
//    @Environment(\.esi) var esi
    
    var body: some View {
//        print(esi)
        print("Hi")
        return Text("")
    }
}

struct ContentView: View {
    @ObservedObject var a: A = A("a")
    @State var esi: ESI = ESI()
	@Environment(\.managedObjectContext) var managedObjectContext
    var body: some View {
		TypeCategories(managedObjectContext: managedObjectContext)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
