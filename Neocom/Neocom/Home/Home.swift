//
//  Home.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct Home: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.account) var account
    
    @State var accountsVisible = false
    var body: some View {
        VStack {
            Button(action: {
                self.accountsVisible = true
            }) {
                HomeHeader(characterID: account?.characterID)
            }
            
            List {
                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            }.listStyle(GroupedListStyle())
        }.sheet(isPresented: $accountsVisible) {
            NavigationView {
                Accounts().navigationBarItems(leading: Button("Cancel") {
                    self.accountsVisible = false
                }).environment(\.managedObjectContext, self.managedObjectContext)
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitle("Neocom")
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Home()
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
