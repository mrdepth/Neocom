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
import Combine

struct CharacterSheetItem: View {
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject private var skills = Lazy<DataLoader<ESI.CharacterSkills, AFError>, Account>()
    @State private var lastUpdateDate = Date()
    
    let require: [ESI.Scope] = [.esiWalletReadCharacterWalletV1,
                                .esiSkillsReadSkillsV1,
                                .esiLocationReadLocationV1,
                                .esiLocationReadShipTypeV1,
                                .esiClonesReadImplantsV1]
    
    private func getPublisher(_ account: Account) -> AnyPublisher<ESI.CharacterSkills, AFError> {
        sharedState.esi.characters.characterID(Int(account.characterID)).skills().get().map{$0.value}.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    private func reload() {
        guard let account = self.sharedState.account else {return}
        guard lastUpdateDate.timeIntervalSinceNow < -30 else {return}
        let result = sharedState.account.map{self.skills.get($0, initial: DataLoader(getPublisher($0)))}
        result?.update(self.getPublisher(account))
        self.lastUpdateDate = Date()
    }

    var body: some View {
        let dataLoader = sharedState.account.map{self.skills.get($0, initial: DataLoader(getPublisher($0)))}
        
        let result = dataLoader?.result
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
        .onReceive(Timer.publish(every: 60 * 30, on: .main, in: .default).autoconnect()) { _ in
            self.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScene.didActivateNotification)) { _ in
            self.reload()
        }
    }
}

#if DEBUG
struct CharacterSheetItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                CharacterSheetItem()
            }.listStyle(GroupedListStyle())
        }
        .modifier(ServicesViewModifier.testModifier())

    }
}
#endif
