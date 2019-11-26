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
    var characterID: Int64? = 1554561480
    
	@ObservedObject private var characterInfo = CharacterInfo(characterImageSize: .size256, corporationImageSize: .size32, allianceImageSize: .size32)

    private func reload() {
		characterInfo.update(esi: esi, characterID: characterID)
    }

    var body: some View {
        return VStack {
			(characterInfo.character?.value).map {
                HomeAccountHeader(characterName: $0.name,
								  corporationName: characterInfo.corporation?.value?.name ?? characterInfo.corporation?.error?.localizedDescription,
                                  allianceName: characterInfo.alliance?.value?.name ?? characterInfo.alliance?.error?.localizedDescription,
								  characterImage: (characterInfo.characterImage?.value).map{Image(uiImage: $0)},
                                  corporationImage: (characterInfo.corporationImage?.value).map{Image(uiImage: $0)},
                                  allianceImage: (characterInfo.allianceImage?.value).map{Image(uiImage: $0)})
                }
        }.onAppear {
            self.reload()
        }
    }
}

struct HomeHeader_Previews: PreviewProvider {
    static var previews: some View {
        HomeHeader()
    }
}
