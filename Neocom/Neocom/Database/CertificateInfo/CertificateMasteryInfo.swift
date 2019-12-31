//
//  CertificateMasteryInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/24/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct CertificateMasteryInfo: View {
    var certificate: SDECertCertificate
    var mastery: Int?
    var pilot: Pilot?
    
    @Environment(\.account) var account
    
    private var masteries: [SDECertMastery] {
        (certificate.masteries?.array as? [SDECertMastery])?.sorted{$0.level!.level < $1.level!.level} ?? []
    }
    
    private func skills(for mastery: SDECertMastery) -> [SDECertSkill] {
        (mastery.skills?.allObjects as? [SDECertSkill])?
//            .filter{$0.skillLevel > 0}
            .sorted {$0.type!.typeName! < $1.type!.typeName!} ?? []
    }
    
    private func title(for mastery: SDECertMastery) -> some View {
        let tq = TrainingQueue(pilot: pilot ?? .empty)
        tq.add(mastery)
        let trainingTime = tq.trainingTime()
        return Group {
            if trainingTime > 0 && account != nil {
                HStack {
                    Text("LEVEL \(String(roman: Int(mastery.level!.level + 1))) (\(TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds)))")
                    Spacer()
                    Button(action: {
                    }) {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            else {
                Text("LEVEL \(String(roman: Int(mastery.level!.level + 1)))")
            }
        }
    }
    
    var body: some View {
        Group {
            CertificateInfoHeader(certificate: self.certificate, masteryLevel: self.mastery)
            ForEach(self.masteries, id: \.objectID) { mastery in
                Section(header: self.title(for: mastery)) {
                    ForEach(self.skills(for: mastery), id: \.objectID) { skill in
                        TypeInfoSkillCell(skillType: skill.type!, level: Int(skill.skillLevel), pilot: self.pilot)
                    }
                }
            }
        }
    }
}

struct CertificateMasteryInfo_Previews: PreviewProvider {
    static var previews: some View {
        let certificate = try! AppDelegate.sharedDelegate.persistentContainer.viewContext
        .from(SDECertCertificate.self)
        .first()!

        return List {
            CertificateMasteryInfo(certificate: certificate)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        }.listStyle(GroupedListStyle())
    }
}
