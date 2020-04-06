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
//    var account: Account
//    var esi: ESI
    
    @ObservedObject var characterInfo: CharacterInfo
    @ObservedObject var accountInfo: AccountInfo

    var body: some View {
        AccountCellContent(character: (characterInfo.character?.value).map{AccountCellContent.Subject(name: $0.name, image: (characterInfo.characterImage?.value).map{Image(uiImage: $0)})},
                           corporation: (characterInfo.corporation?.value).map{AccountCellContent.Subject(name: $0.name, image: (characterInfo.corporationImage?.value).map{Image(uiImage: $0)})},
                           alliance: (characterInfo.alliance?.value).map{AccountCellContent.Subject(name: $0.name, image: (characterInfo.allianceImage?.value).map{Image(uiImage: $0)})},
                           ship: accountInfo.ship?.value?.shipName,
                           location: (accountInfo.location?.value).map{"\($0.solarSystemName ?? "") / \($0.constellation?.region?.regionName ?? "")"},
                           sp: accountInfo.skills?.value?.totalSP,
                           isk: accountInfo.balance?.value,
                           skill: nil,
                           skillQueue: accountInfo.skillQueue?.value?.count)
            
    }
}

struct AccountCell_Previews: PreviewProvider {
    static var previews: some View {
        let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        return AccountCell(characterInfo: CharacterInfo(esi: esi, characterID: account!.characterID),
                           accountInfo: AccountInfo(esi: esi, characterID: account!.characterID, managedObjectContext: context))
    }
}
