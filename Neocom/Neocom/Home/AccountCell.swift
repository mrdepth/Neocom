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
//    var esi: ESI
    
    @ObservedObject var characterInfo: CharacterInfo
    @ObservedObject var accountInfo: AccountInfo
    @Environment(\.managedObjectContext) private var managedObjectContext

    var body: some View {
        let date = Date()
        let item = accountInfo.skillQueue?.value?.filter{($0.finishDate ?? .distantPast) > date}
            .min{$0.finishDate! < $1.finishDate!}
        
        let character: AccountCellContent.Subject
        if let info = characterInfo.character?.value {
            character = AccountCellContent.Subject(name: info.name, image: characterInfo.characterImage?.value.map{Image(uiImage: $0)})
        }
        else {
            character = AccountCellContent.Subject(name: account.characterName ?? "", image: characterInfo.characterImage?.value.map{Image(uiImage: $0)})
        }
//        
        return AccountCellContent(character: character,
                           corporation: (characterInfo.corporation?.value).map{AccountCellContent.Subject(name: $0.name, image: (characterInfo.corporationImage?.value).map{Image(uiImage: $0)})},
                           alliance: (characterInfo.alliance?.value).map{AccountCellContent.Subject(name: $0.name, image: (characterInfo.allianceImage?.value).map{Image(uiImage: $0)})},
                           ship: accountInfo.ship?.value?.shipName,
                           location: (accountInfo.location?.value).map{"\($0.solarSystemName ?? "") / \($0.constellation?.region?.regionName ?? "")"},
                           sp: accountInfo.skills?.value?.totalSP,
                           isk: accountInfo.balance?.value,
                           skill: item,
                           skillQueue: accountInfo.skillQueue?.value?.count,
                           error: characterInfo.character?.error)
            
    }
}

#if DEBUG
struct AccountCell_Previews: PreviewProvider {
    static var previews: some View {
        let context = Storage.testStorage.persistentContainer.viewContext
        let account = Account.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        return AccountCell(account: account!,
                           characterInfo: CharacterInfo(esi: esi, characterID: account!.characterID),
                           accountInfo: AccountInfo(esi: esi, characterID: account!.characterID, managedObjectContext: context))
            .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
