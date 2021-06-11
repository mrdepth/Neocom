//
//  FittingDroneCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/4/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingDroneCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @ObservedObject var drone: DGMDroneGroup
    @State private var isActionsPresented = false
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState

    private var velocity: some View {
        let velocity = drone.velocity * DGMSeconds(1)
        return Group {
            if velocity > 0.1 {
                HStack(spacing: 0) {
                    Icon(Image("velocity"), size: .small)
                    Text(" velocity: ") +
                        Text(UnitFormatter.localizedString(from: velocity, unit: .meterPerSecond, style: .long)).fontWeight(.semibold)
                }.modifier(SecondaryLabelModifier())
            }
        }
    }
    
    var body: some View {
        let type = drone.type(from: managedObjectContext)
        
        let stateImage = (drone.isActive && drone.isKamikaze) ? Image("overheated") : drone.isActive ? Image("active") : Image("offline")
        
        return Button(action: {self.isActionsPresented = true}) {
            HStack {
                (type?.image).map{Icon($0).cornerRadius(4)}
                VStack(alignment: .leading, spacing: 0) {
                    (type?.typeName).map{Text($0)} ?? Text("Unknown")
                    OptimalInfo(optimal: drone.optimal, falloff: drone.falloff).modifier(SecondaryLabelModifier())
                    velocity
                }
                Spacer()
                HStack(spacing: 0) {
                    if drone.target != nil {
                        Icon(Image("targets"), size: .small)
                    }
                    Icon(stateImage, size: .small)
                }
                if drone.drones.count > 1 {
                    Text("x\(drone.drones.count)").fontWeight(.semibold).modifier(SecondaryLabelModifier())
                }
                
            }.contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .adaptivePopover(isPresented: $isActionsPresented, arrowEdge: .leading) {
            NavigationView {
                FittingDroneActions(drone: self.drone) {
                    self.isActionsPresented = false
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .frame(idealWidth: 375, idealHeight: 375 * 2)
        }
    }
}

#if DEBUG
struct FittingDroneCell_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let pilot = gang.pilots[0]
        let dominix = pilot.ship!

        let drone = DGMDroneGroup(dominix.drones)
        
        return List {
            FittingDroneCell(drone: drone)
        }.listStyle(GroupedListStyle())
        .modifier(ServicesViewModifier.testModifier())
        .environmentObject(gang)
    }
}
#endif
