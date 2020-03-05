//
//  FittingDroneActions.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible
import CoreData

struct FittingDroneTypeInfo: View {
    @ObservedObject var drone: DGMDroneGroup
    var type: SDEInvType
    @Environment(\.self) private var environment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Icon(type.image).cornerRadius(4)
                Text(type.typeName ?? "")
                Text("x\(UnitFormatter.localizedString(from: drone.count, unit: .none, style: .long))").modifier(SecondaryLabelModifier())
            }
            type.dgmppItem?.damage.map {
                ChargeDamage(damage: $0)
            }
            
        }
    }
}

struct FittingDroneActions: View {
    @ObservedObject var drone: DGMDroneGroup
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    
    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self)
            .filter(/\SDEInvType.typeID == Int32(drone.typeID)).first()
        return List {
            Section(header: Text("DRONE")) {
                type.map { type in
                    HStack {
                        FittingDroneTypeInfo(drone: drone, type: type)
                        Spacer()
                        TypeInfoButton(type: type)
                    }
                }
                Picker("State", selection: $drone.isActive) {
                    Text("Inactive").tag(false)
                    Text("Active").tag(true)
                }.pickerStyle(SegmentedPickerStyle())
            }
            Section(header: Text("COUNT")) {
                Picker("Count", selection: $drone.count) {
                    ForEach(Array(1..<6), id: \.self) { i in
                        Text("\(i)")
                    }
                }.pickerStyle(WheelPickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                
            }
        }.listStyle(GroupedListStyle())
            .navigationBarTitle("Actions")
    }
}

struct FittingDroneActions_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let drone = DGMDroneGroup(gang.pilots.first!.ship!.drones)
        
        return NavigationView {
            FittingDroneActions(drone: drone)
                .environmentObject(gang)
                .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
                .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        }
    }
}
