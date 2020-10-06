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
import Alamofire

struct TypeInfo: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject var typeInfo: Lazy<TypeInfoData, Never> = Lazy()
    
    @UserDefault(key: .marketRegionID)
    var marketRegionID: Int32 = SDERegionID.default.rawValue
    
    var type: SDEInvType
    var attributeValues: [Int: Double]?
    
    init(type: SDEInvType) {
        self.type = type
    }
    
    private var attributes: FetchedResultsController<SDEDgmTypeAttribute> {
        let controller = managedObjectContext.from(SDEDgmTypeAttribute.self)
            .filter(/\SDEDgmTypeAttribute.type == type && /\SDEDgmTypeAttribute.attributeType?.published == true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, ascending: true)
            .sort(by: \SDEDgmTypeAttribute.attributeType?.attributeID, ascending: true)
            .fetchedResultsController(sectionName: /\SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, cacheName: nil)
        return FetchedResultsController(controller)
    }
    
    private func typeInfoData() -> TypeInfoData {
        let info = TypeInfoData(type: type,
                                esi: sharedState.esi,
                                characterID: sharedState.account?.characterID,
                                marketRegionID: Int(marketRegionID),
								managedObjectContext: backgroundManagedObjectContext,
								override: nil)
        return info
    }
    
    var body: some View {
        let info = self.typeInfo.get(initial: self.typeInfoData())
        let categoryID = (type.group?.category?.categoryID).flatMap { SDECategoryID(rawValue: $0)}
        
        return GeometryReader { geometry in
            List {
                Section {
                    TypeInfoHeader(type: self.type,
                                   renderImage: info.renderImage.map{Image(uiImage: $0)},
                                   preferredMaxLayoutWidth: geometry.size.width - 30).listRowInsets(EdgeInsets())
                }
                
                if self.type.marketGroup != nil {
                    Section(header: Text("MARKET")) {
                        TypeInfoPriceCell(type: self.type)
                        TypeInfoMarketHistoryCell(type: self.type)
                    }
                }
                
                if self.type.parentType != nil || (self.type.variations?.count ?? 0) > 0 {
                    Section(header: Text("VARIATIONS")) {
                        TypeInfoVariationsCell(type: self.type)
                    }
                }
                
                if categoryID == .entity {
                    NPCInfo(type: self.type)
                }
                else if categoryID == .blueprint {
                    BlueprintInfo(type: self.type, pilot: info.pilot)
                }
                else if self.type.wormhole != nil {
                    WormholeInfo(type: self.type)
                }
                else {
                    self.basicInfo(for: info.pilot)
                }
            }.listStyle(GroupedListStyle()).navigationBarTitle(Text("Info"))
        }
    }
}

extension TypeInfo {

    private func basicInfo(for section: FetchedResultsController<SDEDgmTypeAttribute>.Section, pilot: Pilot?) -> some View {
        let attributeCategory = section.objects.first?.attributeType?.attributeCategory
        let categoryID = attributeCategory.flatMap{SDEAttributeCategoryID(rawValue: $0.categoryID)}
        let sectionTitle: String = categoryID == .null ? NSLocalizedString("Other", comment: "") : attributeCategory?.categoryName ?? NSLocalizedString("Other", comment: "")
        
        return Group {
            if categoryID == .requiredSkills {
                TypeInfoRequiredSkillsSection(type: type, pilot: pilot)
            }
            else {
                Section(header: Text(sectionTitle.uppercased())) {
                    ForEach(section.objects, id: \.objectID) { attribute in
                        AttributeInfo(attribute: attribute, attributeValues: self.attributeValues)
                    }
                }
            }
        }
    }
    
    private func basicInfo(for pilot: Pilot?) -> some View {
        let blueprints = Set((type.products?.allObjects as? [SDEIndProduct])?.compactMap{$0.activity?.blueprintType?.type} ?? []).sorted{$0.typeName! < $1.typeName!}
        let skillLevels: Range<Int>
        let skill = Pilot.Skill(type: type)
        if skill != nil {
            let level = pilot?.trainedSkills[Int(type.typeID)]?.trainedSkillLevel ?? 0
            skillLevels = (level + 1)..<6
        }
        else {
            skillLevels = 0..<0
        }
        
        return Group {
            if !skillLevels.isEmpty && skill != nil {
                Section(header: Text("SKILL PLAN")) {
                    ForEach(skillLevels) { level in
                        SkillLevelCell(type: self.type, skill: skill!, level: level, pilot: pilot)
                    }
                }
            }
            if !blueprints.isEmpty {
                Section(header: Text("MANUFACTURING")) {
                    ForEach(blueprints, id: \.objectID) { type in
                        TypeInfoAttributeCell(title: Text(type.typeName ?? ""),
                                              image: type.image,
                                              targetType: type)
                    }
                }
            }
            ForEach(attributes.sections, id: \.name) { section in
                self.basicInfo(for: section, pilot: pilot)
            }
        }
    }
}

#if DEBUG
struct TypeInfo_Previews: PreviewProvider {
    static var previews: some View {
//        let account = Account(token: oAuth2Token, context: Storage.sharedStorage.persistentContainer.viewContext)
        return NavigationView {
            TypeInfo(type: .gallenteCarrier)
//                .environment(\.account, account)
//                .environment(\.esi, ESI(token: oAuth2Token))
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
