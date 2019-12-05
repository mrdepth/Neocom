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
    @Environment(\.esi) var esi
    @Environment(\.account) var account
    
    var type: SDEInvType
    
    private func typeInfoData() -> TypeInfoData {
        let info = TypeInfoData(type: type, esi: esi, characterID: account?.characterID, managedObjectContext: managedObjectContext, override: nil)
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
        ObservedObjectView(typeInfoData()) { info in
            GeometryReader { geometry in
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
//                                if row.attribute != nil {
//                                    TypeInfoAttributeCell(attribute: row.attribute!)
//                                }
//                                else if row.damage != nil {
//                                    TypeInfoDamageCell(damage: row.damage!)
//                                }
////                                else if row.skill != nil {
////                                    TypeInfoSkillCell(skill: row.skill!)
////                                }
//                                else if row.variations != nil {
//                                    TypeInfoVariationsCell(variations: row.variations!)
//                                }
                            }
                        }
                    }
                }.listStyle(GroupedListStyle()).navigationBarTitle("Info")
            }
        }
    }
}

struct TypeInfo_Previews: PreviewProvider {
    static var previews: some View {
//        let account = Account(token: oAuth2Token, context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        return NavigationView {
            TypeInfo(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!)
                .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
//                .environment(\.account, account)
//                .environment(\.esi, ESI(token: oAuth2Token))
        }
    }
}

