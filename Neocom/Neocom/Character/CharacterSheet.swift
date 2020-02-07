//
//  CharacterSheet.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible

struct CharacterSheet: View {
    @ObservedObject private var characterInfo = Lazy<CharacterFullInfo>()
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.esi) var esi
    @Environment(\.account) var account

    private var title: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Artem Valiant").font(.title)
            HStack {
                Icon(Image("corporation"))
                Text("Necrorise Squadron")
            }
            HStack {
                Icon(Image("alliance"))
                Text("Red Alert")
            }
        }
        .background(Color(.systemFill))
        .padding()
        .colorScheme(.dark)

    }
    
    private func dateOfBirth(from info: ESI.CharacterInfo) -> some View {
        VStack(alignment: .leading) {
            Text("Date of Birth")
            Text(DateFormatter.localizedString(from: info.birthday, dateStyle: .medium, timeStyle: .none)).modifier(SecondaryLabelModifier())
        }
    }

    
    private func securityStatus(from info: ESI.CharacterInfo) -> some View {
        info.securityStatus.map { securityStatus in
            VStack(alignment: .leading) {
                Text("Security Status")
                Text(security: Float(securityStatus)).modifier(SecondaryLabelModifier())
            }
        }
    }
    
    private func bloodline(from info: ESI.CharacterInfo) -> some View {
        let bloodline = try? self.managedObjectContext.from(SDEChrBloodline.self).filter(\SDEChrBloodline.bloodlineID == info.bloodlineID).first()?.bloodlineName
        return bloodline.map { bloodline in
            VStack(alignment: .leading) {
                Text("Bloodline")
                Text(bloodline).modifier(SecondaryLabelModifier())
            }
        }
    }
    
    private func ship(_ ship: ESI.Ship?, location: SDEMapSolarSystem?) -> some View {
        ship.flatMap { ship in
            try? self.managedObjectContext.from(SDEInvType.self).filter(\SDEInvType.typeID == ship.shipTypeID).first()
        }.map { ship in
            NavigationLink(destination: TypeInfo(type: ship)) {
                HStack {
                    Icon(ship.image).cornerRadius(4)
                    VStack(alignment: .leading) {
                        Text(ship.typeName ?? "")
                        location.map{EVELocation(solarSystem: $0, id: Int64($0.solarSystemID))}.map{Text($0)}.modifier(SecondaryLabelModifier())
                    }
                }
            }
        }
    }
    
    private func balance(from value: Double) -> some View {
        VStack(alignment: .leading) {
            Text("Balance")
            Text(UnitFormatter.localizedString(from: value, unit: .isk, style: .long)).modifier(SecondaryLabelModifier())
        }
    }
    
    private func skills(from skills: ESI.CharacterSkills?) -> some View {
        skills.map { skills in
            VStack(alignment: .leading) {
                Text("\(skills.skills.count) ") + Text("Skills")
                Text(UnitFormatter.localizedString(from: skills.totalSP, unit: .skillPoints, style: .long)).modifier(SecondaryLabelModifier())
            }
        }
    }
    
    private func bonusRemaps(from attributes: ESI.Attributes?) -> some View {
        attributes.map {attributes in
            VStack(alignment: .leading) {
                Text("Bonus Remaps Available")
                Text("\(attributes.bonusRemaps ?? 0)").modifier(SecondaryLabelModifier())
            }
        }
    }
    
    private func neuralRemap(from attributes: ESI.Attributes?) -> some View {
        attributes.flatMap{$0.lastRemapDate}.flatMap { lastRemapDate -> String? in
            let calendar = Calendar(identifier: .gregorian)
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: lastRemapDate)
            components.year? += 1
            guard let date = calendar.date(from: components) else {return nil}
            let t = date.timeIntervalSinceNow
            let s: String
            
            if t <= 0 {
                s = NSLocalizedString("Now", comment: "")
            }
            else if t < 3600 * 24 * 7 {
                s = TimeIntervalFormatter.localizedString(from: t, precision: .minutes)
            }
            else {
                s = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
            }
            return s
        }.map { s in
            VStack(alignment: .leading) {
                Text("Neural Remap Available")
                Text(s).modifier(SecondaryLabelModifier())
            }
        }
    }
    
    private func attributesSection(from attributes: ESI.Attributes?) -> some View {
        let rows = [(Text("Intelligence", comment: ""), Image("intelligence"), attributes?.intelligence),
                    (Text("Memory", comment: ""), Image("memory"), attributes?.memory),
                    (Text("Perception", comment: ""), Image("perception"), attributes?.perception),
                    (Text("Willpower", comment: ""), Image("willpower"), attributes?.willpower),
                    (Text("Charisma", comment: ""), Image("charisma"), attributes?.charisma)]
        
        return attributes.map { attributes in
            Section(header: Text("ATTRIBUTES")) {
                ForEach(0..<5) { i in
                    HStack {
                        Icon(rows[i].1)
                        VStack(alignment: .leading) {
                            rows[i].0
                            Text("\(rows[i].2 ?? 0)").modifier(SecondaryLabelModifier())
                        }
                    }
                }
            }
        }
    }
    
    private func implantsSection(from implants: ESI.Implants?) -> some View {
        return implants.map { implants in
            Section(header: Text("IMPLANTS")) {
                ImplantsRows(implants: implants)
            }
        }
    }
    
    var body: some View {
        let characterInfo = account.map {account in self.characterInfo.get(initial: CharacterFullInfo(esi: esi, characterID: account.characterID, managedObjectContext: managedObjectContext, characterImageSize: .size1024, corporationImageSize: .size128, allianceImageSize: .size128))}
        return Group {
            if characterInfo != nil {
                List {
                    Section {
                        if characterInfo?.character != nil {
                            CharacterSheetHeader(characterName: characterInfo?.character?.value?.name,
                                                 characterImage: characterInfo?.characterImage?.value,
                                                 corporationName: characterInfo?.corporation?.value?.name,
                                                 corporationImage: characterInfo?.corporationImage?.value,
                                                 allianceName: characterInfo?.alliance?.value?.name,
                                                 allianceImage: characterInfo?.allianceImage?.value).listRowInsets(EdgeInsets())
                        }
                    }
                    (characterInfo?.character?.value).map { info in
                        Section(header: Text("BIO")) {
                            self.dateOfBirth(from: info)
                            self.securityStatus(from: info)
                            self.bloodline(from: info)
                            self.ship(characterInfo?.ship?.value, location: characterInfo?.location?.value)
                        }
                    }
                    (characterInfo?.balance?.value).map{ balance in
                        Section(header: Text("ACCOUNT")) {
                            self.balance(from: balance)
                        }
                    }
                    if characterInfo?.skills?.value != nil || characterInfo?.attributes?.value != nil {
                        Section(header: Text("SKILLS")) {
                            self.skills(from: characterInfo?.skills?.value)
                            self.bonusRemaps(from: characterInfo?.attributes?.value)
                            self.neuralRemap(from: characterInfo?.attributes?.value)
                        }
                    }
                    attributesSection(from: characterInfo?.attributes?.value)
                    implantsSection(from: characterInfo?.implants?.value)
                }.listStyle(GroupedListStyle())
            }
            else {
                Text(RuntimeError.noAccount).padding()
            }
        }
    }
}

struct CharacterSheet_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return NavigationView {
            CharacterSheet()
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.account, account)
            .environment(\.esi, esi)
    }
}
