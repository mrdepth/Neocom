//
//  KillImailInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/4/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible
import Dgmpp
import Combine

struct KillImailInfo: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.account) private var account

    var killmail: ESI.Killmail
    var contacts: [Int64: Contact]
    
    private var victim: some View {
        HStack {
            killmail.victim.characterID.map{Avatar(characterID: Int64($0), size: .size256).frame(width: 40, height: 40)}
            VStack(alignment: .leading) {
                killmail.victim.characterID.flatMap{contacts[Int64($0)]?.name}.map{Text($0)} ?? Text("Unknown")
                Text([killmail.victim.corporationID.flatMap{contacts[Int64($0)]?.name},
                      killmail.victim.allianceID.flatMap{contacts[Int64($0)]?.name}].compactMap{$0}.joined(separator: " / ")).modifier(SecondaryLabelModifier())
            }
        }
    }
    
    private func victimShip(type: SDEInvType?) -> some View {
        HStack {
            type.map{Icon($0.image).cornerRadius(4)}
            VStack(alignment: .leading) {
                type?.typeName.map{Text($0)} ?? Text("Unknown ship")
                Text("\(UnitFormatter.localizedString(from: killmail.victim.damageTaken, unit: .none, style: .long)) damage taken").modifier(SecondaryLabelModifier())
            }
        }
    }
    
    private func itemsRows(from types: [SDEInvType], items: [Int: Int64]) -> some View {
        ForEach(types, id: \.objectID) { type in
            NavigationLink(destination: TypeInfo(type: type)) {
                HStack {
                    Icon(type.image).cornerRadius(4)
                    VStack(alignment: .leading) {
                        Text(type.typeName ?? "")
                        Text("Qty: \(UnitFormatter.localizedString(from: items[Int(type.typeID)] ?? 0, unit: .none, style: .long))").modifier(SecondaryLabelModifier())
                    }
                }
            }
        }
    }
    
    private var dropped: some View {
        let pairs = killmail.victim.items?.filter{($0.quantityDropped ?? 0) > 0} ?? []
        let items = Dictionary(pairs.map{($0.itemTypeID, $0.quantityDropped!)}) {a, b in a + b}
        let types = (try? managedObjectContext
            .from(SDEInvType.self)
            .filter((/\SDEInvType.typeID).in(items.keys.map{Int32($0)}))
            .sort(by: \SDEInvType.typeName, ascending: true)
            .fetch()) ?? []
        
        return Group {
            if !types.isEmpty {
                Section(header: Text("DROPPED")) {
                    itemsRows(from: types, items: items)
                }
            }
        }
    }
    
    private var destroyed: some View {
        let pairs = killmail.victim.items?.filter{($0.quantityDestroyed ?? 0) > 0} ?? []
        let items = Dictionary(pairs.map{($0.itemTypeID, $0.quantityDestroyed!)}) {a, b in a + b}
        let types = (try? managedObjectContext
            .from(SDEInvType.self)
            .filter((/\SDEInvType.typeID).in(items.keys.map{Int32($0)}))
            .sort(by: \SDEInvType.typeName, ascending: true)
            .fetch()) ?? []
        
        return Group {
            if !types.isEmpty {
                Section(header: Text("DESTROYED")) {
                    itemsRows(from: types, items: items)
                }
            }
        }
    }
    
    private var location: some View {
        let solarSystem = try? managedObjectContext.from(SDEMapSolarSystem.self).filter(/\SDEMapSolarSystem.solarSystemID == Int32(killmail.solarSystemID)).first()
        return Group {
            if solarSystem != nil {
                VStack(alignment: .leading) {
                    Text(EVELocation(solarSystem: solarSystem!, id: Int64(solarSystem!.solarSystemID))) + Text(" / ") + Text(solarSystem?.constellation?.region?.regionName ?? "")
                    Text(DateFormatter.localizedString(from: killmail.killmailTime, dateStyle: .medium, timeStyle: .medium)).modifier(SecondaryLabelModifier())
                }
            }
        }
    }
    
    @State private var selectedProject: FittingProject?
    @State private var projectLoading: AnyPublisher<Result<FittingProject, Error>, Never>?

    private var fittingButton: some View {
        Button("Fitting") {
            self.projectLoading = DGMSkillLevels.load(self.account, managedObjectContext: self.managedObjectContext).tryMap { try FittingProject(killmail: self.killmail, skillLevels: $0) }
                .asResult()
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }
    
    
    var body: some View {
        let ship = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(killmail.victim.shipTypeID)).first()
        let attackers = killmail.attackers.sorted{($0.finalBlow ? 1 : 0, $0.damageDone) > ($1.finalBlow ? 1 : 0, $1.damageDone)}
        
        return List {
            Section(header: Text("VICTIM")) {
                victim
                if ship != nil {
                    NavigationLink(destination: TypeInfo(type: ship!)) {
                        victimShip(type: ship!)
                    }
                }
                else {
                    victimShip(type: ship!)
                }
                location
            }
            dropped
            destroyed
            if !attackers.isEmpty {
                ForEach(0..<attackers.count) { i in
                    AttackerCell(attacker: attackers[i], contacts: self.contacts)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .overlay(self.projectLoading != nil ? ActivityView() : nil)
        .overlay(selectedProject.map{NavigationLink(destination: FittingEditor(project: $0), tag: $0, selection: $selectedProject, label: {EmptyView()})})
        .onReceive(projectLoading ?? Empty().eraseToAnyPublisher()) { result in
            self.projectLoading = nil
            self.selectedProject = result.value
        }
        .navigationBarTitle("Killmail")
        .navigationBarItems(trailing: fittingButton)
    }
}

struct AttackerCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var attacker: ESI.Attacker
    var contacts: [Int64: Contact]
    
    func ship(_ type: SDEInvType) -> some View {
        let damageDone = UnitFormatter.localizedString(from: attacker.damageDone, unit: .none, style: .long)
        return HStack {
            Icon(type.image).cornerRadius(4)
            VStack(alignment: .leading) {
                Text(type.typeName ?? "")
                if attacker.finalBlow {
                    Text("\(damageDone) damage done (final blow)").modifier(SecondaryLabelModifier())
                }
                else {
                    Text("\(damageDone) damage done").modifier(SecondaryLabelModifier())
                }
            }
        }
    }
    
    var body: some View {
        let ship = attacker.shipTypeID.flatMap{try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32($0)).first()}
        let contact = attacker.characterID.flatMap{contacts[Int64($0)]?.name}
        
        let content = VStack(alignment: .leading) {
            if contact != nil {
                HStack {
                    attacker.characterID.map{Avatar(characterID: Int64($0), size: .size256).frame(width: 40, height: 40)}
                    VStack(alignment: .leading) {
                        Text(contact!)
                        Text([attacker.corporationID.flatMap{contacts[Int64($0)]?.name},
                              attacker.allianceID.flatMap{contacts[Int64($0)]?.name}].compactMap{$0}.joined(separator: " / ")).modifier(SecondaryLabelModifier())
                    }
                }
            }
            if ship != nil {
                self.ship(ship!)
            }
        }
        
        return Group {
            if ship != nil {
                NavigationLink(destination: TypeInfo(type: ship!)) {
                    content
                }
            }
            else {
                content
            }
        }
    }
}

struct KillImailInfo_Previews: PreviewProvider {
    static var previews: some View {
        let killmail = try! ESI.jsonDecoder.decode(ESI.Killmail.self, from: NSDataAsset(name: "killmail")!.data)
        let contacts: [Int64: Contact] = [
            94786446: .testContact(contactID: 94786446, name: "Character1"),
            94221668: .testContact(contactID: 94221668, name: "Character2"),
            98586687: .testContact(contactID: 98586687, name: "Corporation")
        ]

        return NavigationView {
            KillImailInfo(killmail: killmail, contacts: contacts)
        }
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
