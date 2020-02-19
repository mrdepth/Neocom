//
//  Skills.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/22/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire
import Expressible

struct Skills: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    private func skills() -> FetchedResultsController<SDEInvType> {
        let controller = managedObjectContext
            .from(SDEInvType.self)
            .filter(Expressions.keyPath(\SDEInvType.published) == true && Expressions.keyPath(\SDEInvType.group?.category?.categoryID) == SDECategoryID.skill.rawValue)
            .sort(by: \SDEInvType.group?.groupName, ascending: true)
            .sort(by: \SDEInvType.typeName, ascending: true)
            .fetchedResultsController(sectionName: Expressions.keyPath(\SDEInvType.group?.groupName), cacheName: nil)
        return FetchedResultsController(controller)
    }

    var body: some View {
        ObservedObjectView(self.skills()) { skills in
            SkillsContent(skills: skills)
        }.navigationBarTitle("Skills")
    }
}

struct SkillsContent: View {
    var skills: FetchedResultsController<SDEInvType>
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account
    @State private var filter = SkillsFilter.Filter.my
    @ObservedObject private var pilot = Lazy<DataLoader<Pilot, AFError>>()
    
    private func loadPilot(account: Account) -> DataLoader<Pilot, AFError> {
        DataLoader(Pilot.load(esi.characters.characterID(Int(account.characterID)), in: self.backgroundManagedObjectContext).receive(on: RunLoop.main))
    }
    
    private func subtitle(for skills: [SDEInvType], pilot: Pilot) -> Text {
        
        let items = skills.compactMap { type -> (skill: Pilot.Skill, type: SDEInvType, trained: ESI.Skill?, queued: Pilot.SkillQueueItem?)? in
            guard let skill = Pilot.Skill(type: type) else {return nil}
            let typeID = Int(type.typeID)
            let trainedSkill = pilot.trainedSkills[Int(typeID)]
            let queuedSkill = pilot.skillQueue.filter{$0.queuedSkill.skillID == typeID}.min{$0.queuedSkill.finishedLevel < $1.queuedSkill.finishedLevel}
            return (skill, type, trainedSkill, queuedSkill)
        }
        switch filter {
        case .my:
            let skills = items.compactMap{$0.trained}
            let sp = skills.map{$0.skillpointsInSkill}.reduce(0, +)
            return Text("\(skills.count) Skills, \(UnitFormatter.localizedString(from: sp, unit: .skillPoints, style: .long))")
        case .canTrain:
            let skills = items.filter{($0.trained?.trainedSkillLevel ?? 0) < 5}
            let mySP = items.compactMap{$0.trained?.skillpointsInSkill}.map{Int64($0)}.reduce(0, +)
            let totalSP = items.map{i in (1...5).map{Int64(i.skill.skillPoints(at: $0))}.reduce(0, +)}.reduce(0, +)
            return Text("\(skills.count) Skills, \(UnitFormatter.localizedString(from: totalSP - mySP, unit: .skillPoints, style: .long))")
        case .notKnown:
            let skills = items.filter{$0.trained == nil}
            let sp = skills.map{i in (1...5).map{Int64(i.skill.skillPoints(at: $0))}.reduce(0, +)}.reduce(0, +)
            return Text("\(skills.count) Skills, \(UnitFormatter.localizedString(from: sp, unit: .skillPoints, style: .long))")
        case .all:
            let sp = items.map{i in (1...5).map{Int64(i.skill.skillPoints(at: $0))}.reduce(0, +)}.reduce(0, +)
            return Text("\(items.count) Skills, \(UnitFormatter.localizedString(from: sp, unit: .skillPoints, style: .long))")
        }
    }
    
    var body: some View {
        let pilot = account.map{account in self.pilot.get(initial: self.loadPilot(account: account))}?.result?.value// ?? .some(.empty)
        
        return List {
            Section(header: SkillsFilter(filter: $filter)) {
                ForEach(skills.sections, id: \.name) { section in
                    NavigationLink(destination: SkillsPage(skills: section, filter: self.$filter, pilot: pilot)) {
                        VStack(alignment: .leading) {
                            Text(section.name)
                            pilot.map { pilot in
                                self.subtitle(for: section.objects, pilot: pilot).modifier(SecondaryLabelModifier())
                            }
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
}


struct SkillsFilter: View {
    @Binding var filter: Filter
    
    enum Filter {
        case my
        case canTrain
        case notKnown
        case all
    }

    var body: some View {
        Picker(selection: $filter, label: Text("Filter")) {
            Text("My").tag(Filter.my)
            Text("Can Train").tag(Filter.canTrain)
            Text("Not Known").tag(Filter.notKnown)
            Text("All").tag(Filter.all)
        }.pickerStyle(SegmentedPickerStyle())
    }
}


struct Skills_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return NavigationView {
            Skills()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environment(\.account, account)
        .environment(\.esi, esi)
    }
}
