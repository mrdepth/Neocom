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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private func title() -> some View {
        VStack(alignment: .leading) {
            Text(type.typeName ?? "").font(.title).foregroundColor(.primary)
            Text(type.group?.category?.categoryName ?? "") + Text(" / ") + Text(type.group?.groupName ?? "")
        }.foregroundColor(.secondary)
    }
    
    var body: some View {
        let renderImageView = renderImage?.resizable().scaledToFit()
            .overlay(title()
                .padding(8)
                .background(Color(.systemFill).cornerRadius(8))
                .padding().colorScheme(.dark), alignment: .bottomLeading)

        
        return VStack(alignment: .leading) {
            if renderImageView != nil {
                if horizontalSizeClass == .regular {
                    renderImageView!
                        .frame(maxWidth: 512)
                        .cornerRadius(8)
                        .padding([.horizontal, .top], 15)
                }
                else {
                    renderImageView!
                }
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

#if DEBUG
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
        .environmentObject(SharedState.testState())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
#endif
