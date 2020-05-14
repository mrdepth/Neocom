//
//  KillmailCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/3/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible
import Alamofire
import Combine

enum KillmailType {
    case kill
    case loss
}

struct KillmailData {
    var typeName: Text
    var image: Image?
    var solarSystem: Text?
}

struct KillmailCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var killmail: Result<ESI.Killmail, AFError>
    var contacts: [Int64: Contact]
    var cache: Cache<Int64, DataLoader<KillmailData, Never>>
    
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    
    private func getData(killmail: ESI.Killmail) -> DataLoader<KillmailData, Never> {
        let publisher = Future<KillmailData, Never> { promise in
            self.backgroundManagedObjectContext.perform {
                let ship = try? self.backgroundManagedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(killmail.victim.shipTypeID)).first()
                let solarSystem = try? self.backgroundManagedObjectContext.from(SDEMapSolarSystem.self).filter(/\SDEMapSolarSystem.solarSystemID == Int32(killmail.solarSystemID)).first()
                
                let data = KillmailData(typeName: ship?.typeName.map{Text($0)} ?? Text("Unknown Type"),
                                        image: ship?.image,
                                        solarSystem: solarSystem.map { solarSystem in
                                            Text(security: solarSystem.security) + Text(solarSystem.solarSystemName ?? "")
                })
                promise(.success(data))
            }
        }.receive(on: DispatchQueue.main)
        return DataLoader(publisher)
    }
    
    var body: some View {
        let value = killmail.value
        let error = killmail.error
        
        return Group {
            if value != nil {
                NavigationLink(destination: KillImailInfo(killmail: value!, contacts: contacts)) {
                    KillmailCellContent(killmail: value!, contacts: contacts, data: cache[Int64(value!.killmailID), default: self.getData(killmail: value!)])
                }
            }
            else if error != nil {
                Text(error!)
            }
        }
    }
}

struct KillmailCellContent: View {
    var killmail: ESI.Killmail
    var contacts: [Int64: Contact]
    @ObservedObject var data: DataLoader<KillmailData, Never>
    
    
    var body: some View {
        let data = self.data.result?.value

        return HStack {
            data?.image.map{Icon($0).cornerRadius(4)}
            VStack(alignment: .leading) {
                data?.typeName ?? Text(" ")
                (data?.solarSystem ?? Text(" "))?.modifier(SecondaryLabelModifier())
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(DateFormatter.localizedString(from: killmail.killmailTime, dateStyle: .medium, timeStyle: .none))
                Text(DateFormatter.localizedString(from: killmail.killmailTime, dateStyle: .none, timeStyle: .short))
            }.modifier(SecondaryLabelModifier())
            
        }
    }
}

#if DEBUG
struct KillmailCell_Previews: PreviewProvider {
    static var previews: some View {
        let killmail = try! ESI.jsonDecoder.decode(ESI.Killmail.self, from: NSDataAsset(name: "killmail")!.data)
        let contacts: [Int64: Contact] = [
            94786446: .testContact(contactID: 94786446, name: "Character1"),
            94221668: .testContact(contactID: 94221668, name: "Character2"),
            98586687: .testContact(contactID: 98586687, name: "Corporation")
        ]

        return List {
            KillmailCell(killmail: .success(killmail), contacts: contacts, cache: Cache())
//            KillmailCellContent(killmail: killmail, contacts: contacts, cache: Cache())
        }.listStyle(GroupedListStyle())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
//        KillmailCell(killmailID: 82925944, hash: "3a20a8149ea41a80554d2469383caef1a8e4cdad")
    }
}
#endif
