//
//  Wealth.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/21/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import CoreData

struct Wealth: View {
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account
    @ObservedObject var wealth = Lazy<WealthData>()
    
    private func cell(_ title: Text, value: Double?) -> some View {
        Group {
            if value != nil && value! > 0 {
                VStack(alignment: .leading) {
                    title
                    Text("\(UnitFormatter.localizedString(from: value!, unit: .isk, style: .long))").modifier(SecondaryLabelModifier())
                }
            }
        }
    }
    
    var body: some View {
        let wealth = account.map{self.wealth.get(initial: WealthData(esi: esi, characterID: $0.characterID, managedObjectContext: backgroundManagedObjectContext))}

        return List {
            Section {
                WealthChart(sections: [
                    WealthChart.Section(title: Text("Account"), amount: wealth?.wallet?.value ?? 0, color: .secondary),
                    WealthChart.Section(title: Text("Industry"), amount: wealth?.industry?.value ?? 0, color: .red),
                    WealthChart.Section(title: Text("Market"), amount: wealth?.marketOrders?.value ?? 0, color: .blue),
                    WealthChart.Section(title: Text("Blueprints"), amount: wealth?.blueprints?.value ?? 0, color: .skyBlue),
                    WealthChart.Section(title: Text("Implants"), amount: wealth?.implants?.value ?? 0, color: .green),
                    WealthChart.Section(title: Text("Contracts"), amount: wealth?.contracts?.value ?? 0, color: .yellow),
                    WealthChart.Section(title: Text("Assets"), amount: wealth?.assets?.value ?? 0, color: .purple)
                ])
            }
            Section {
                self.cell(Text("Account"), value: wealth?.wallet?.value)
                self.cell(Text("Industry"), value: wealth?.industry?.value)
                self.cell(Text("Market"), value: wealth?.marketOrders?.value)
                self.cell(Text("Blueprints"), value: wealth?.blueprints?.value)
                self.cell(Text("Implants"), value: wealth?.implants?.value)
                self.cell(Text("Contracts"), value: wealth?.contracts?.value)
                self.cell(Text("Assets"), value: wealth?.assets?.value)
            }
        }.listStyle(GroupedListStyle())
            .navigationBarTitle("Wealth")
        
    }
}

struct Wealth_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        return NavigationView {
            Wealth()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environment(\.account, account)
        .environment(\.esi, esi)

    }
}
