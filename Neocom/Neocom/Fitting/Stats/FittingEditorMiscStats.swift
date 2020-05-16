//
//  FittingEditorMiscStats.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

fileprivate protocol Column {}

struct FittingEditorMiscStats: View {
    private enum LeftColumn: Column {}
    private enum RightColumn: Column {}
    @ObservedObject var ship: DGMShip
    @State private var leftColumnWidth: CGFloat?
    @State private var rightColumnWidth: CGFloat?
    
    private func leftCell(title: Text, image: Image, value: String) -> some View {
        HStack {
            Icon(image, size: .small)
            title.frame(maxWidth: .infinity, alignment: .leading)
            Text(value).fixedSize().sizePreference(LeftColumn.self).frame(width: leftColumnWidth, alignment: .leading)
        }
    }
    private func rightCell(title: Text, image: Image, value: String) -> some View {
        HStack {
            Icon(image, size: .small)
            title.frame(maxWidth: .infinity, alignment: .leading)
            Text(value).fixedSize().sizePreference(RightColumn.self).frame(width: rightColumnWidth, alignment: .leading)
        }
    }
    
    var body: some View {
        Section(header: Text("MISC")) {
            HStack {
                if ship is DGMStructure {
                    VStack(alignment: .leading, spacing: 2) {
                        leftCell(title: Text("Targets:"), image: Image("targets"), value: "\(ship.maxTargets)")
                        leftCell(title: Text("Scan res.:"), image: Image("scanResolution"), value: UnitFormatter.localizedString(from: ship.scanResolution, unit: .millimeter, style: .long))
                        leftCell(title: Text("Sensor str.:"), image: Image("gravimetric"), value: "\(Int(ship.scanStrength))")
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        rightCell(title: Text("Signature:"), image: Image("signature"), value: "\(Int(ship.signatureRadius))")
                        rightCell(title: Text("Range:"), image: Image("targetingRange"), value: UnitFormatter.localizedString(from: ship.maxTargetRange, unit: .meter, style: .short))
                        leftCell(title: Text("Mass:"), image: Image("mass"), value: UnitFormatter.localizedString(from: ship.mass, unit: .kilogram, style: .short))
                        
                    }.frame(maxWidth: .infinity, alignment: .leading)

                }
                else {
                    VStack(alignment: .leading, spacing: 2) {
                        leftCell(title: Text("Targets:"), image: Image("targets"), value: "\(ship.maxTargets)")
                        leftCell(title: Text("Range:"), image: Image("targetingRange"), value: UnitFormatter.localizedString(from: ship.maxTargetRange, unit: .meter, style: .short))
                        leftCell(title: Text("Scan res.:"), image: Image("scanResolution"), value: UnitFormatter.localizedString(from: ship.scanResolution, unit: .millimeter, style: .long))
                        leftCell(title: Text("Sensor str.:"), image: Image("gravimetric"), value: "\(Int(ship.scanStrength))")
                        leftCell(title: Text("Drone range:"), image: Image("droneRange"), value: "\(UnitFormatter.localizedString(from: (ship.parent as? DGMCharacter)?.droneControlDistance ?? 0, unit: .meter, style: .short))")
                        leftCell(title: Text("Mass:"), image: Image("mass"), value: UnitFormatter.localizedString(from: ship.mass, unit: .kilogram, style: .short))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        rightCell(title: Text("Speed:"), image: Image("velocity"), value: UnitFormatter.localizedString(from: ship.velocity * DGMSeconds(1), unit: .meterPerSecond, style: .short))
                        rightCell(title: Text("Align time:"), image: Image("align"), value: UnitFormatter.localizedString(from: ship.alignTime, unit: .seconds, style: .long))
                        rightCell(title: Text("Signature:"), image: Image("signature"), value: "\(Int(ship.signatureRadius))")
                        rightCell(title: Text("Cargo:"), image: Image("cargoBay"), value: UnitFormatter.localizedString(from: ship.cargoCapacity, unit: .cubicMeter, style: .short))
                        rightCell(title: Text("Special hold:"), image: Image("cargoBay"), value: UnitFormatter.localizedString(from: ship.specialHoldCapacity, unit: .cubicMeter, style: .short))
                        rightCell(title: Text("Warp speed:"), image: Image("warpSpeed"), value: UnitFormatter.localizedString(from: ship.warpSpeed * DGMSeconds(1), unit: .auPerSecond, style: .long))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }.font(.caption)
                .onSizeChange(LeftColumn.self) {self.leftColumnWidth = $0.map{$0.width}.max()}
                .onSizeChange(RightColumn.self) {self.rightColumnWidth = $0.map{$0.width}.max()}
            .lineLimit(1)
        }
    }
}

struct FittingEditorMiscStats_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return List {
            FittingEditorMiscStats(ship: gang.pilots.first!.ship!)
        }.listStyle(GroupedListStyle())
//            .environmentObject(DGMStructure.testKeepstar() as DGMShip)
            .environmentObject(gang)
            .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
