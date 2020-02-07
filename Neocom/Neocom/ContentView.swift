//
//  ContentView.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

class A: ObservableObject {
    @Published var i = 10
    
    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.i = 20
        }
    }
}

struct Child: View {
    var body: some View {
        ObservedObjectView(A()) { a in
            Text("a.i = \(a.i)")
            ForEach((0..<a.i).map{$0}, id: \.self) { i in
                Text("\(i)")
            }
        }
    }
}

struct ContentView: View {
    @State var b = false
    @State var l = (0..<10).map{"\($0)"}
    
    
    func f(_ s: String) -> String {
        print(s)
        return s
    }
    
    @State private var isFinished = false
    
    var body: some View {
        
        ZStack {
//            TextFieldAlert_Previews.previews
//            SkillPlans_Previews.previews
            Assets_Previews.previews
//            NavigationView {
//                TypeCategories()
//            }
            if isFinished {
                FinishedView(isPresented: $isFinished)
            }
        }.onReceive(NotificationCenter.default.publisher(for: .didUpdateSkillPlan)) { _ in
            withAnimation {
                self.isFinished = true
            }
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
