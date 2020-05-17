//
//  ZKillboardSearchForm.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/2/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import CoreData

private let startDate: Date = {
    let calendar = Calendar(identifier: .gregorian)
    return calendar.date(from: DateComponents(year: 2003, month: 5, day: 6))!
}()

struct ZKillboardSearchForm: View {
    struct Filter {
        var from = startDate
        var to = Date()
        var pilot: Contact?
        var location: NSManagedObject?
        var ship: NSManagedObject?
        var soloOnly = false
        var whOnly = false
    }

    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.self) private var environment
    @State private var filter = Filter()

    @State private var isContactsPresented = false
    @State private var isShipPickerPresented = false
    @State private var isLocationPickerPresented = false
    
    private var pilotButton: some View {
        HStack {
            Button(action: {self.isContactsPresented = true}) {
                if filter.pilot != nil {
                    ContactCell(contact: filter.pilot!).contentShape(Rectangle())
                }
                else {
                    HStack {
                        Text("Pilot/Corporation/Alliance")
                        Spacer()
                        Text("Any").foregroundColor(.secondary)
                    }.frame(height: 30).contentShape(Rectangle())
                }
            }.buttonStyle(PlainButtonStyle())
            Spacer()
            if filter.pilot != nil {
                Button(NSLocalizedString("Clear", comment: "")) {
                    withAnimation {
                        self.filter.pilot = nil
                    }
                }
            }
        }
        
        .sheet(isPresented: $isContactsPresented) {
            NavigationView {
                ContactPicker { contact in
                    self.filter.pilot = contact
                    self.isContactsPresented = false
                }.navigationBarItems(leading: BarButtonItems.close {
                    self.isContactsPresented = false
                })
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private var shipButton: some View {
        HStack {
            Button(action: {self.isShipPickerPresented = true}) {
                if filter.ship != nil {
                    HStack {
                        if filter.ship is SDEInvType {
                            TypeCell(type: filter.ship as! SDEInvType)
                        }
                        else if filter.ship is SDEInvGroup {
                            GroupCell(group: filter.ship as! SDEInvGroup)
                        }
                        Spacer()
                    }.contentShape(Rectangle())
                }
                else {
                    HStack {
                        Text("Ship")
                        Spacer()
                        Text("Any").foregroundColor(.secondary)
                    }.frame(height: 30).contentShape(Rectangle())
                }
            }.buttonStyle(PlainButtonStyle())
            Spacer()
            if filter.ship != nil {
                Button(NSLocalizedString("Clear", comment: "")) {
                    withAnimation {
                        self.filter.ship = nil
                    }
                }
            }
        }
        
        .sheet(isPresented: $isShipPickerPresented) {
            NavigationView {
                ShipPicker { ship in
                    self.filter.ship = ship
                    self.isShipPickerPresented = false
                }.navigationBarItems(leading: BarButtonItems.close {
                    self.isShipPickerPresented = false
                })
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private var locationButton: some View {
        HStack {
            Button(action: {self.isLocationPickerPresented = true}) {
                if filter.location != nil {
                    HStack {
                        if filter.location is SDEMapRegion {
                            Text((filter.location as! SDEMapRegion).regionName ?? "")
                        }
                        else if filter.location is SDEMapSolarSystem {
                            SolarSystemCell(solarSystem: filter.location as! SDEMapSolarSystem)
                        }
                        Spacer()
                    }.contentShape(Rectangle())
                }
                else {
                    HStack {
                        Text("Location")
                        Spacer()
                        Text("Any").foregroundColor(.secondary)
                    }.frame(height: 30).contentShape(Rectangle())
                }
            }.buttonStyle(PlainButtonStyle())
            Spacer()
            if filter.location != nil {
                Button(NSLocalizedString("Clear", comment: "")) {
                    withAnimation {
                        self.filter.location = nil
                    }
                }
            }
        }
        
        .sheet(isPresented: $isLocationPickerPresented) {
            NavigationView {
                LocationPicker { location in
                    self.filter.location = location
                    self.isLocationPickerPresented = false
                }.navigationBarItems(leading: BarButtonItems.close {
                    self.isLocationPickerPresented = false
                })
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    var wSpaceCell: some View {
        Toggle(isOn: $filter.whOnly) {
            Text("W-Space")
        }
    }

    var soloCell: some View {
        Toggle(isOn: $filter.soloOnly) {
            Text("Solo")
        }
    }

    var body: some View {
        let values = filter.values
        
        return List {
            Section(footer: Text("Select at least one modifier")) {
                pilotButton
                shipButton
                if !filter.whOnly {
                    locationButton
                }
                if filter.location == nil {
                    wSpaceCell
                }
                soloCell
                
                DatePicker(selection: $filter.from, in: startDate...filter.to, displayedComponents: .date) {
                    Text("From Date")
                }
                DatePicker(selection: $filter.to, in: filter.from...Date(), displayedComponents: .date) {
                    Text("To Date")
                }
            }
            Section {
                NavigationLink(NSLocalizedString("Kills", comment: ""), destination: ZKillboardSearchResults(filter: values + [.kills]))
                NavigationLink(NSLocalizedString("Losses", comment: ""), destination: ZKillboardSearchResults(filter: values + [.losses]))
            }.disabled(values.isEmpty)
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text("zKillboard"))
    }
}

extension ZKillboardSearchForm.Filter {
    var values: [ZKillboard.Filter] {
        var values = [ZKillboard.Filter]()
        if let pilot = pilot {
            switch pilot.recipientType {
            case .character?:
                values.append(.characterID([pilot.contactID]))
            case .corporation?:
                values.append(.corporationID([pilot.contactID]))
            case .alliance?:
                values.append(.allianceID([pilot.contactID]))
            default:
                break
            }
        }
        
        switch ship {
        case let type as SDEInvType:
            values.append(.shipTypeID([Int(type.typeID)]))
        case let group as SDEInvGroup:
            values.append(.groupID([Int(group.groupID)]))
        default:
            break
        }
        
        switch location {
        case let solarSystem as SDEMapSolarSystem:
            values.append(.solarSystemID([Int(solarSystem.solarSystemID)]))
        case let region as SDEMapRegion:
            values.append(.regionID([Int(region.regionID)]))
        default:
            break
        }
        
        if soloOnly {
            values.append(.solo)
        }
        
        if whOnly && location == nil {
            values.append(.wSpace)
        }
        
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let endDate = calendar.date(from: components)!

        
        if from > startDate {
            values.append(.startTime(from))
        }
        if to < endDate {
            values.append(.endTime(to))
        }
        return values
    }
}

#if DEBUG
struct ZKillboardSearchForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ZKillboardSearchForm()
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
#endif
