//
//  CertificateCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/24/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

struct CertificateCell: View {
    var certificate: SDECertCertificate
    var pilot: Pilot?
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
    
    struct TargetLevel {
        var level: Int
        var trainingTime: TimeInterval
    }
    
    private func trainingInfo() -> AnyPublisher<TargetLevel?, Never> {
        guard let pilot = pilot else {return Just(nil).eraseToAnyPublisher()}
        let context = backgroundManagedObjectContext
        return Future { promise in
            context.perform {
                
                let certificate = try! context.existingObject(with: self.certificate.objectID) as! SDECertCertificate
                let result = (certificate.masteries?.array as? [SDECertMastery])?.sorted {$0.level!.level < $1.level!.level}.lazy.map { mastery -> TargetLevel in
                    let tq = TrainingQueue(pilot: pilot)
                    tq.add(mastery)
                    return TargetLevel(level: Int(mastery.level!.level), trainingTime: tq.trainingTime())
                }.first {$0.trainingTime > 0}
                
                promise(.success(result))
                
//                if let result = result {
//                    let subtitle: LocalizedStringKey = "\(TimeIntervalFormatter.localizedString(from: result.1, precision: .seconds)) to level \(result.0.level!.level + 1)"
//                    let image = try? context.fetch(SDEEveIcon.named(.mastery(Int(result.0.level!.level - 1)))).first?.image?.image
//                    promise(.success((subtitle: subtitle, image: image)))
//                }
//                else {
//                    let image = try? context.fetch(SDEEveIcon.named(.mastery(4))).first?.image?.image
//                    promise(.success((subtitle: nil, image: image)))
//                }
            }
        }.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    var body: some View {
        ObservedObjectView(DataLoader(trainingInfo())) { trainingInfo in
            NavigationLink(destination: CertificateInfo(certificate: self.certificate, mastery: trainingInfo.result?.value??.level, pilot: self.pilot)) {
                HStack {
                    Icon(Image(uiImage: (try? self.managedObjectContext.fetch(SDEEveIcon.named(.mastery((trainingInfo.result?.value??.level).map{$0 - 1}))).first?.image?.image) ?? UIImage()))
                    VStack(alignment: .leading) {
                        Text(self.certificate.certificateName ?? "")
                        (trainingInfo.result?.value ?? nil).map{Text("\(TimeIntervalFormatter.localizedString(from: $0.trainingTime, precision: .seconds)) to level \($0.level + 1)")}.modifier(SecondaryLabelModifier())
                    }
                }
            }
        }
    }
}



struct CertificateCell_Previews: PreviewProvider {
    static var previews: some View {
        let certificate = try! AppDelegate.sharedDelegate.persistentContainer.viewContext
            .from(SDECertCertificate.self)
            .first()!
        
        return NavigationView {
            List {
                CertificateCell(certificate: certificate, pilot: .empty)
                CertificateCell(certificate: certificate, pilot: nil)
            }.listStyle(GroupedListStyle())
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext.newBackgroundContext())
    }
}
