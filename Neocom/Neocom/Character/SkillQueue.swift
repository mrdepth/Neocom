//
//  SkillQueue.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/28/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Alamofire
import EVEAPI
import Expressible

struct SkillQueue: View {
    @ObservedObject private var pilot = Lazy<DataLoader<Pilot, AFError>>()
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account

    private func loadPilot(account: Account) -> DataLoader<Pilot, AFError> {
        DataLoader(Pilot.load(esi.characters.characterID(Int(account.characterID)), in: self.backgroundManagedObjectContext).receive(on: RunLoop.main))
    }

    var body: some View {
        let pilot = account.map{account in self.pilot.get(initial: self.loadPilot(account: account))}?.result?.value

        return List {
            pilot.map { pilot in
                SkillQueueSection(pilot: pilot)
            }
        }.listStyle(GroupedListStyle())
    }
}



struct SkillQueue_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return SkillQueue()
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
            .environment(\.account, account)
            .environment(\.esi, esi)
    }
}
