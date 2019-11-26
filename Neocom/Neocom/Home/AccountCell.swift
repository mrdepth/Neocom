//
//  AccountCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible
import Alamofire

struct AccountCell: View {
    var account: Account
    var esi: ESI
    
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject private var characterInfo = CharacterInfo(characterImageSize: .size256, corporationImageSize: .size32, allianceImageSize: .size32)
    @ObservedObject private var skillQueue = DataLoader<[ESI.Characters.CharacterID.Skillqueue.Success], AFError>()
    @ObservedObject private var ship = DataLoader<ESI.Characters.CharacterID.Ship.Success, AFError>()
    @ObservedObject private var location = DataLoader<SDEMapSolarSystem, AFError>()
    @ObservedObject private var sp = DataLoader<Int64, AFError>()
    @ObservedObject private var isk = DataLoader<Double, AFError>()
    
    private func reload() {
        characterInfo.update(esi: esi, characterID: account.characterID)
        
        let character = esi.characters.characterID(Int(account.characterID))
        
        
        skillQueue.update(character.skillqueue().get()
            .map{$0.filter{$0.finishDate.map{$0 > Date()} == true}}
            .receive(on: DispatchQueue.main))
        
        ship.update(character.ship().get().receive(on: DispatchQueue.main))
        
        sp.update(character.skills().get().map { $0.totalSP }.receive(on: DispatchQueue.main))
        isk.update(character.wallet().get().receive(on: DispatchQueue.main))
        
        location.update(character.location().get().receive(on: DispatchQueue.main).compactMap { location in
            try? self.managedObjectContext.from(SDEMapSolarSystem.self).filter(\SDEMapSolarSystem.solarSystemID == Int32(location.solarSystemID)).first()
        })
    }

    var body: some View {
        AccountCellContent(character: (characterInfo.character?.value).map{AccountCellContent.Subject(name: $0.name, image: (characterInfo.characterImage?.value).map{Image(uiImage: $0)})},
                           corporation: (characterInfo.corporation?.value).map{AccountCellContent.Subject(name: $0.name, image: (characterInfo.corporationImage?.value).map{Image(uiImage: $0)})},
                           alliance: (characterInfo.alliance?.value).map{AccountCellContent.Subject(name: $0.name, image: (characterInfo.allianceImage?.value).map{Image(uiImage: $0)})},
                           ship: ship.result?.value?.shipName,
                           location: (location.result?.value).map{"\($0.solarSystemName ?? "") / \($0.constellation?.region?.regionName ?? "")"},
                           sp: sp.result?.value,
                           isk: isk.result?.value,
                           skill: nil,
                           skillQueue: skillQueue.result?.value?.count)
            .onAppear() {
                self.reload()
        }
    }
}

struct AccountCell_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).testingContainer.viewContext
        let account = try! context.from(Account.self).first()!
        return AccountCell(account: account, esi: ESI(token: account.oAuth2Token!)).environment(\.managedObjectContext, context)
    }
}
