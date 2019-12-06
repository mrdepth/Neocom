//
//  TypeInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/2/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible

struct TypeInfo: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
    @Environment(\.esi) var esi
    @Environment(\.account) var account
    @ObservedObject var typeInfo: Lazy<TypeInfoData> = Lazy()
    
    var type: SDEInvType
    
    init(type: SDEInvType) {
        self.type = type
    }
    
    private func typeInfoData() -> TypeInfoData {
        let info = TypeInfoData(type: type,
								esi: esi,
								characterID: account?.characterID,
								managedObjectContext: backgroundManagedObjectContext,
								override: nil)
        return info
    }
    
    private func cell(for row: TypeInfoData.Row) -> AnyView {
        switch row {
        case let .attribute(attribute):
            return AnyView(TypeInfoAttributeCell(attribute: attribute))
        case let .damage(damage):
            return AnyView(TypeInfoDamageCell(damage: damage))
        case let .skill(skill):
            return AnyView(TypeInfoSkillCell(skill: skill))
        case let .variations(variations):
            return AnyView(TypeInfoVariationsCell(variations: variations))
        case let .mastery(mastery):
            return AnyView(TypeInfoMasteryCell(mastery: mastery))
        }
    }
    
    var body: some View {
        let info = self.typeInfo.get(initial: self.typeInfoData())
            return GeometryReader { geometry in
                
//				ObservedObjectView(self.typeInfoData()) { info in
                List {
                    Section {
                        TypeInfoHeader(type: self.type,
                                       renderImage: info.renderImage.map{Image(uiImage: $0)},
                                       preferredMaxLayoutWidth: geometry.size.width - 30).listRowInsets(EdgeInsets())
                    }

                    ForEach(info.sections) { section in
                        Section(header: Text(section.name)) {
                            ForEach(section.rows) { row in
                                self.cell(for: row)
                            }
                        }
                    }
                }.listStyle(GroupedListStyle()).navigationBarTitle("Info")
//            }
        }
    }
}

struct TypeInfo_Previews: PreviewProvider {
    static var previews: some View {
//        let account = Account(token: oAuth2Token, context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        return NavigationView {
            TypeInfo(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!)
                .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
                .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext.newBackgroundContext())
//                .environment(\.account, account)
//                .environment(\.esi, ESI(token: oAuth2Token))
        }
    }
}

