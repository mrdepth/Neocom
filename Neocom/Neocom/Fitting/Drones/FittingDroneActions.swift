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
                DamageVectorView(damage: DGMDamageVector($0))
            }
            
        }
    }
}

struct FittingDroneActions: View {
    @ObservedObject var drone: DGMDroneGroup
    var completion: () -> Void
    
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
            Section {
                Stepper("\(drone.count) Drones", value: $drone.count, in: 1...drone.squadronSize)
            }
        }.listStyle(GroupedListStyle())
            .navigationBarTitle("Actions")
            .navigationBarItems(leading: BarButtonItems.close(completion), trailing: BarButtonItems.trash {
                self.completion()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    let ship = self.drone.parent as? DGMShip
                    self.drone.drones.forEach { ship?.remove($0) }
                }
            })

    }
}

struct FittingDroneActions_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let drone = DGMDroneGroup(gang.pilots.first!.ship!.drones)
        
        return NavigationView {
            FittingDroneActions(drone: drone) {}
                .environmentObject(gang)
                .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
                .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        }
    }
}
