//
//  HomeHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/22/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine
import EVEAPI
import Alamofire

struct HomeHeader: View {
    @Environment(\.account) var account
    @Environment(\.esi) var esi
    @ObservedObject var characterInfo = Lazy<CharacterInfo>()
    
//	@ObservedObject private var characterInfo = CharacterInfo(characterImageSize: .size256, corporationImageSize: .size32, allianceImageSize: .size32)

    var body: some View {
        let characterInfo = account.map{self.characterInfo.get(initial: CharacterInfo(esi: esi, characterID: $0.characterID, characterImageSize: .size256, corporationImageSize: .size32, allianceImageSize: .size32))}
        let error = characterInfo?.character?.error
        
        return VStack(spacing: 0) {
            
            if characterInfo != nil {
                HomeAccountHeader(characterName: characterInfo?.character?.value?.name ?? "",
                                  corporationName: characterInfo?.corporation?.value?.name ?? characterInfo?.corporation?.error?.localizedDescription,
                                  allianceName: characterInfo?.alliance?.value?.name ?? characterInfo?.alliance?.error?.localizedDescription,
                                  characterImage: (characterInfo?.characterImage?.value).map{Image(uiImage: $0)},
                                  corporationImage: (characterInfo?.corporationImage?.value).map{Image(uiImage: $0)},
                                  allianceImage: (characterInfo?.allianceImage?.value).map{Image(uiImage: $0)})
                    .overlay(characterInfo?.character == nil ? ActivityIndicator(style: .medium) : nil)
            }
            else if error != nil {
                VStack {
                    Avatar(image: nil).frame(width: 64, height: 64).overlay(Image(systemName: "person").resizable().padding())
                    Text(error!).padding()
                }.padding().foregroundColor(.secondary)
            }
            else {
                HomeLoginHeader()
            }
        }
    }
}

struct HomeHeader_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return HomeHeader()
            .environment(\.account, account)
            .environment(\.esi, esi)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)

    }
}
