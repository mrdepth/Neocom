//
//  Avatar.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire

struct Avatar: View {
    enum Source {
        case image(Image?)
        case character(Int64, ESI.Image.Size)
        case corporation(Int64, ESI.Image.Size)
        case alliance(Int64, ESI.Image.Size)
    }
    
    private var source: Source
//    @ObservedObject private var imageLoader = Lazy<DataLoader<UIImage, AFError>>()
    @Environment(\.esi) private var esi

    init(image: Image?) {
        source = .image(image)
    }
    
    init(characterID: Int64, size: ESI.Image.Size) {
        source = .character(characterID, size)
    }

    init(corporationID: Int64, size: ESI.Image.Size) {
        source = .corporation(corporationID, size)
    }

    init(allianceID: Int64, size: ESI.Image.Size) {
        source = .alliance(allianceID, size)
    }

    var body: some View {
        /*let image: Image?
        let isCharacter: Bool
        switch source {
        case let .image(value):
            image = value
            isCharacter = true
        case let .character(characterID, size):
            let uiImage = imageLoader.get(initial: DataLoader(esi.image.character(Int(characterID), size: size))).result?.value
            image = uiImage.map{Image(uiImage: $0)}
            isCharacter = true
        case let .corporation(corporationID, size):
            let uiImage = imageLoader.get(initial: DataLoader(esi.image.corporation(Int(corporationID), size: size))).result?.value
            image = uiImage.map{Image(uiImage: $0)}
            isCharacter = false
        case let .alliance(allianceID, size):
            let uiImage = imageLoader.get(initial: DataLoader(esi.image.alliance(Int(allianceID), size: size))).result?.value
            image = uiImage.map{Image(uiImage: $0)}
            isCharacter = false
        }*/
        let isCharacter: Bool
        switch source {
        case .character, .image:
            isCharacter = true
        default:
            isCharacter = false
        }
        
        let image = AvatarImageView(esi: esi, source: source)
        
        return Group {
            if isCharacter {
                ZStack {
                    Color(UIColor.systemGroupedBackground)
                    image
                }
                .clipShape(Circle())
                .shadow(radius: 2)
                .overlay(Circle().strokeBorder(Color(UIColor.tertiarySystemBackground), lineWidth: 2, antialiased: true))
            }
            else {
                image
            }
        }
    }
}

struct AvatarImageView: View {
    var esi: ESI
    var source: Avatar.Source
    
    @ObservedObject private var imageLoader = Lazy<DataLoader<UIImage, AFError>>()

    var body: some View {
        let image: Image?
        switch source {
        case let .image(value):
            image = value
        case let .character(characterID, size):
            let uiImage = imageLoader.get(initial: DataLoader(esi.image.character(Int(characterID), size: size))).result?.value
            image = uiImage.map{Image(uiImage: $0)}
        case let .corporation(corporationID, size):
            let uiImage = imageLoader.get(initial: DataLoader(esi.image.corporation(Int(corporationID), size: size))).result?.value
            image = uiImage.map{Image(uiImage: $0)}
        case let .alliance(allianceID, size):
            let uiImage = imageLoader.get(initial: DataLoader(esi.image.alliance(Int(allianceID), size: size))).result?.value
            image = uiImage.map{Image(uiImage: $0)}
        }
        
        return Group {
            if image != nil {
                image!.resizable()
            }
            else {
                Color.clear
            }
        }
    }
}

struct Avatar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Avatar(image: Image("character")).frame(width: 64, height: 64).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.light)
            Avatar(image: Image("character")).frame(width: 64, height: 64).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.dark)
            Avatar(image: nil).frame(width: 64, height: 64).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.light)
            Avatar(image: nil).frame(width: 64, height: 64).padding().background(Color(UIColor.systemGroupedBackground)).colorScheme(.dark)
            Avatar(characterID: 1554561480, size: .size128).frame(width: 64, height: 64)
            Avatar(corporationID: 653533005, size: .size128).frame(width: 64, height: 64)
        }
    }
}
