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
    private enum Source {
        case image(Image?)
        case character(Int64, ESI.Image.Size)
    }
    
    private var source: Source
    @ObservedObject private var imageLoader = Lazy<DataLoader<UIImage, AFError>>()
    @Environment(\.esi) private var esi

    init(image: Image?) {
        source = .image(image)
    }
    
    init(characterID: Int64, size: ESI.Image.Size) {
        source = .character(characterID, size)
    }
    
    var body: some View {
        let image: Image?
        switch source {
        case let .image(value):
            image = value
        case let .character(characterID, size):
            let uiImage = imageLoader.get(initial: DataLoader(esi.image.character(Int(characterID), size: size))).result?.value
            image = uiImage.map{Image(uiImage: $0)}
        }
        
        return ZStack {
            Color(UIColor.systemGroupedBackground)
            image?.resizable()
        }
        .clipShape(Circle())
        .shadow(radius: 2)
        .overlay(Circle().strokeBorder(Color(UIColor.tertiarySystemBackground), lineWidth: 2, antialiased: true))
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
        }
    }
}
