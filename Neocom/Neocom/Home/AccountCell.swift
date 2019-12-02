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
    
    @ObservedObject var accountInfo: AccountInfo

    var body: some View {
        AccountCellContent(character: (accountInfo.characterInfo.character?.value).map{AccountCellContent.Subject(name: $0.name, image: (accountInfo.characterInfo.characterImage?.value).map{Image(uiImage: $0)})},
                           corporation: (accountInfo.characterInfo.corporation?.value).map{AccountCellContent.Subject(name: $0.name, image: (accountInfo.characterInfo.corporationImage?.value).map{Image(uiImage: $0)})},
                           alliance: (accountInfo.characterInfo.alliance?.value).map{AccountCellContent.Subject(name: $0.name, image: (accountInfo.characterInfo.allianceImage?.value).map{Image(uiImage: $0)})},
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
        let context = (UIApplication.shared.delegate as! AppDelegate).testingContainer.viewContext
        let account = try! context.from(Account.self).first()!
        let esi = ESI(token: account.oAuth2Token!)
        return AccountCell(accountInfo: AccountInfo(esi: esi, characterID: account.characterID, managedObjectContext: context, characterImageSize: .size256))
//        return AccountCell(account: account, esi: ESI(token: account.oAuth2Token!)).environment(\.managedObjectContext, context)
    }
}
