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
                    (renderImage ?? type.image).resizable().scaledToFit().frame(width: 64, height: 64).cornerRadius(8).edgesIgnoringSafeArea(.horizontal)
                    title()
                }.padding([.horizontal, .top])
            }
            AttributedText(type.typeDescription?.text?.extract(with: .preferredFont(forTextStyle: .body), color: .descriptionLabel) ?? NSAttributedString()).padding([.horizontal, .bottom])
        }
    }
}

struct TypeInfoHeader_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TypeInfoHeader(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!, renderImage: nil)
//                .padding()
                .background(Color(UIColor.systemBackground))
                .colorScheme(.light)
            VStack {
                TypeInfoHeader(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!, renderImage: Image("dominix"))
//                    .padding()
                    .background(Color(UIColor.systemBackground))
                Spacer()
            }.colorScheme(.dark)
                //.background(Color.gray)
        }
    }
}

