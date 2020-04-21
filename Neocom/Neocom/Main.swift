//
//  Main.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible

struct FinishedViewWrapper: View {
    @State private var isFinished = false
    
    var body: some View {
        Group {
            if isFinished {
                FinishedView(isPresented: $isFinished)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateSkillPlan)) { _ in
            withAnimation {
                self.isFinished = true
            }
        }

    }
}

struct Main: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
//    @ObservedObject private var accountID = UserDefault(wrappedValue: String?.none, key: .activeAccountID)
    @EnvironmentObject private var sharedState: SharedState
    
    private let home = Home()

    var body: some View {
//        let account = try? managedObjectContext.from(Account.self).filter(/\Account.uuid == accountID.wrappedValue).first()
//        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        
        return ZStack {
            NavigationView {
                home
            }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            FinishedViewWrapper()
        }
        .environmentObject(sharedState)

    }
}

struct Main_Previews: PreviewProvider {
    static var previews: some View {
        return Main()
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environmentObject(SharedState.testState())

    }
}
