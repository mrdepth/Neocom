//
//  CharacterSheetItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire

struct CharacterSheetItem: View {
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var skills = Lazy<DataLoader<ESI.CharacterSkills, AFError>>()
    
    let require: [ESI.Scope] = [.esiWalletReadCharacterWalletV1,
                                .esiSkillsReadSkillsV1,
                                .esiLocationReadLocationV1,
                                .esiLocationReadShipTypeV1,
                                .esiClonesReadImplantsV1]
    
    var body: some View {
        let result = sharedState.account.map{self.skills.get(initial: DataLoader(sharedState.esi.characters.characterID(Int($0.characterID)).skills().get().map{$0.value}.receive(on: RunLoop.main)))}?.result
        let skills = result?.value
        let error = result?.error
        return Group {
            if sharedState.account?.verifyCredentials(require) == true {
                NavigationLink(destination: CharacterSheet()) {
                    Icon(Image("charactersheet"))
                    VStack(alignment: .leading) {
                        Text("Character Sheet")
                        if skills != nil {
                            Text(UnitFormatter.localizedString(from: skills!.totalSP, unit: .skillPoints, style: .long)).modifier(SecondaryLabelModifier())
                        }
                        else if error != nil {
                            Text(error!).modifier(SecondaryLabelModifier())
                        }
                    }
                }
            }
        }
    }
}

struct CharacterSheetItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                CharacterSheetItem()
            }.listStyle(GroupedListStyle())
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(SharedState.testState())

    }
}
