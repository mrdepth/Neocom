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
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject var characterInfo = Lazy<CharacterInfo, Account>()
    @State private var lastUpdateDate = Date()
    
    private func reload(_ info: CharacterInfo) {
        guard lastUpdateDate.timeIntervalSinceNow < -30 else {return}
        self.lastUpdateDate = Date()
        info.update(cachePolicy: .useProtocolCachePolicy)
    }
    
    var body: some View {
        let characterInfo = sharedState.account.map{self.characterInfo.get($0, initial: CharacterInfo(esi: sharedState.esi, characterID: $0.characterID, characterImageSize: .size256, corporationImageSize: .size32, allianceImageSize: .size32))}
        let error = characterInfo?.character?.error
        return VStack(spacing: 0) {
            if characterInfo != nil {
                HomeAccountHeader(characterName: characterInfo?.character?.value?.name ?? sharedState.account?.characterName ?? " ",
                                  corporationName: characterInfo?.corporation?.value?.name ?? characterInfo?.corporation?.error?.localizedDescription,
                                  allianceName: characterInfo?.alliance?.value?.name,// ?? characterInfo?.alliance?.error?.localizedDescription,
                                  characterImage: (characterInfo?.characterImage?.value).map{Image(uiImage: $0)},
                                  corporationImage: (characterInfo?.corporationImage?.value).map{Image(uiImage: $0)},
                                  allianceImage: (characterInfo?.allianceImage?.value).map{Image(uiImage: $0)})
                    .overlay(characterInfo?.character == nil ? ActivityIndicatorView(style: .medium) : nil)
            }
            else if error != nil {
                VStack {
                    Avatar(image: nil).frame(width: 64, height: 64).overlay(Image(systemName: "person").resizable().padding())
                    Text(error!).padding()
                }
                .foregroundColor(.secondary)
                //.padding().foregroundColor(.secondary)
            }
            else {
                HomeLoginHeader()
            }
        }
        .onReceive(Timer.publish(every: 60 * 30, on: .main, in: .default).autoconnect()) { _ in
            guard let info = characterInfo else {return}
            self.reload(info)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScene.didActivateNotification)) { _ in
            guard let info = characterInfo else {return}
            self.reload(info)
        }
    }
}

#if DEBUG
struct HomeHeader_Previews: PreviewProvider {
    static var previews: some View {
        HomeHeader()
            .modifier(ServicesViewModifier.testModifier())

    }
}
#endif
