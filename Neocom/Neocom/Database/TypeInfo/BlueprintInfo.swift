//
//  BlueprintInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/31/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct BlueprintInfo: View {
    var type: SDEInvType
    var pilot: Pilot?
    
    func section(for activity: SDEIndActivity) -> some View {
        let products = (activity.products?.allObjects as? [SDEIndProduct])?.filter {$0.productType?.typeName != nil}.sorted {$0.productType!.typeName! < $1.productType!.typeName!}
        let tq = TrainingQueue(pilot: pilot ?? .empty)
        tq.addRequiredSkills(for: activity)
        let time = tq.trainingTime()
        
        return Section(header: Text(activity.activity?.activityName?.uppercased() ?? "")) {
            ForEach(products ?? [], id: \.objectID) { product in
                TypeInfoAttributeCell(title: Text(product.productType?.typeName ?? ""),
                                      subtitle: Text(product.probability > 0 ? "QTY: \(product.quantity) (\(Int(product.probability * 100))%)" : "QTY: \(product.quantity)"),
                                      image: product.productType?.image,
                                      targetType: product.productType)
            }
            
            HStack {
                Image(systemName: "clock").frame(width: 32, height: 32)
                VStack(alignment: .leading) {
                    Text("Time")
                    Text(TimeIntervalFormatter.localizedString(from: TimeInterval(activity.time), precision: .seconds)).modifier(SecondaryLabelModifier())
                }
            }

            
            if activity.requiredMaterials?.count ?? 0 > 0 {
                NavigationLink(destination: BlueprintActivityMaterials(activity: activity)) {
                    TypeInfoAttributeCell(title: Text("Materials"))
                }
            }
            
            if activity.requiredSkills?.count ?? 0 > 0 {
                NavigationLink(destination: BlueprintActivityRequiredSkills(activity: activity, pilot: pilot)) {
                    TypeInfoAttributeCell(title: Text("Required Skills"),
                                          subtitle: time > 0 ? Text(TimeIntervalFormatter.localizedString(from: time, precision: .seconds)) : nil)
                }
            }
        }
    }
    
    var body: some View {
        let activities = (type.blueprintType?.activities?.allObjects as? [SDEIndActivity])?.sorted {$0.activity!.activityID < $1.activity!.activityID} ?? []
        return ForEach(activities, id: \.objectID) { activity in
            self.section(for: activity)
        }
    }
}

struct BlueprintInfo_Previews: PreviewProvider {
    static var previews: some View {
        let blueprint = (SDEInvType.dominix.products?.anyObject() as? SDEIndProduct)?.activity?.blueprintType?.type
        return NavigationView {
            List {
                BlueprintInfo(type: blueprint!)
            }.listStyle(GroupedListStyle())
        }
    }
}

