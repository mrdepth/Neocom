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

extension Result {
    var value: Success? {
        switch self {
        case let .success(value):
            return value
        default:
            return nil
        }
    }
    var error: Failure? {
        switch self {
        case let .failure(error):
            return error
        default:
            return nil
        }
    }
}

struct HomeHeader: View {
    @Environment(\.account) var account
    @Environment(\.esi) var esi
    var characterID: Int? = 1554561480
    
    private struct Character {
        var character: ESI.Characters.CharacterID.Success
        var corporation: ESI.Corporations.CorporationID.Success
        var alliance: ESI.Alliances.AllianceID.Success?
    }
    @ObservedObject private var character = API<ESI.Characters.CharacterID.Success, AFError>()
    @ObservedObject private var corporation = API<ESI.Corporations.CorporationID.Success, AFError>()
    @ObservedObject private var alliance = API<ESI.Alliances.AllianceID.Success, AFError>()
    @ObservedObject private var characterImage = API<UIImage, AFError>()
    @ObservedObject private var corporationImage = API<UIImage, AFError>()
    @ObservedObject private var allianceImage = API<UIImage, AFError>()

    private func characterPublisher() -> AnyPublisher<ESI.Characters.CharacterID.Success, AFError> {
        CurrentValueSubject(characterID)
            .compactMap{$0}
            .flatMap {
            self.esi.characters.characterID(Int($0)).get()
        }
        .eraseToAnyPublisher()
    }

    private func corporationPublisher() -> AnyPublisher<ESI.Corporations.CorporationID.Success, AFError> {
        character.publisher()
            .compactMap{$0}
//            .tryMap{try $0.get()}
//            .mapError{$0 as! AFError}
            .flatMap {
            self.esi.corporations.corporationID($0.corporationID).get()
        }
        .eraseToAnyPublisher()
    }

    private func alliancePublisher() -> AnyPublisher<ESI.Alliances.AllianceID.Success, AFError> {
        corporation.publisher()
            .compactMap{$0}
            .tryMap{try $0.get()}
            .mapError{$0 as! AFError}
            .compactMap{$0.allianceID}
            .flatMap {
                self.esi.alliances.allianceID($0).get()
        }
        .eraseToAnyPublisher()
    }

    private func reload() {
        character.update(characterPublisher().receive(on: DispatchQueue.main))
        corporation.update(corporationPublisher().receive(on: DispatchQueue.main))
        alliance.update(alliancePublisher().receive(on: DispatchQueue.main))
//        characterImage.update(character.publisher().flatMap{self.esi.image.character($0.va, size: <#T##ESI.Image.Size#>)})
    }

    var body: some View {
        return VStack {
            Text("sdf")
            (character.result?.value).map {
                HomeAccountHeader(characterName: $0.name,
                                  corporationName: corporation.result?.value?.name ?? corporation.result?.error?.localizedDescription,
                                  allianceName: alliance.result?.value?.name ?? alliance.result?.error?.localizedDescription,
                                  characterImage: nil,
                                  corporationImage: nil,
                                  allianceImage: nil)
                }
//            (character?.error).map {Text($0.localizedDescription)} ?? Text("Loading")
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
