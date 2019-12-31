//
//  TypeInfoHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/3/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TypeInfoHeader: View {
    var type: SDEInvType
    var renderImage: Image?
    var preferredMaxLayoutWidth: CGFloat
    
    private func title() -> some View {
        VStack(alignment: .leading) {
            Text(type.typeName ?? "").font(.title).foregroundColor(.primary)
            Text(type.group?.category?.categoryName ?? "") + Text(" / ") + Text(type.group?.groupName ?? "")
        }.foregroundColor(.secondary)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if renderImage != nil {
                renderImage!.resizable().scaledToFit().overlay(title().background(Color(.systemFill)).padding().colorScheme(.dark), alignment: .bottomLeading)
            }
            else {
                HStack {
                    type.image.resizable().scaledToFit().frame(width: 64, height: 64).cornerRadius(8).edgesIgnoringSafeArea(.horizontal)
                    title()
                }.padding([.horizontal, .top], 15)
            }
            AttributedText(type.typeDescription?.text?.extract(with: .preferredFont(forTextStyle: .body), color: .descriptionLabel) ?? NSAttributedString(), preferredMaxLayoutWidth: preferredMaxLayoutWidth).padding([.horizontal, .bottom], 15)
        }
    }
}

struct TypeInfoHeader_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GeometryReader { geometry in
                TypeInfoHeader(type: .dominix, renderImage: nil, preferredMaxLayoutWidth: geometry.size.width - 30)
            }
            .background(Color(UIColor.systemBackground))
            .colorScheme(.light)
            GeometryReader { geometry in
                TypeInfoHeader(type: .dominix, renderImage: Image("dominix"), preferredMaxLayoutWidth: geometry.size.width - 30)
            }
            .background(Color(UIColor.systemBackground))
            .colorScheme(.dark)
                //.background(Color.gray)
        }
    }
}
