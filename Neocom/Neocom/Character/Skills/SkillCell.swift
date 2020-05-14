//
//  SkillCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/22/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import EVEAPI

struct SkillCell: View {
    var type: SDEInvType
    var pilot: Pilot?
    var skillQueueItem: Pilot.SkillQueueItem?
    var skillPlanSkill: SkillPlanSkill?
    var targetLevel: Int?
    var editMode: Bool
    @EnvironmentObject private var sharedState: SharedState

    private static var counter: Int = 0
    private static func getID() -> Int {
        defer {counter += 1}
        return counter
    }
    
    init(type: SDEInvType, pilot: Pilot?, editMode: Bool = false) {
        self.type = type
        self.pilot = pilot
        self.editMode = editMode
    }
    
    init(type: SDEInvType, pilot: Pilot?, skillQueueItem: Pilot.SkillQueueItem?, editMode: Bool = false) {
        self.type = type
        self.pilot = pilot
        self.skillQueueItem = skillQueueItem
        self.editMode = editMode
    }
    
    init(type: SDEInvType, pilot: Pilot?, skillPlanSkill: SkillPlanSkill?, editMode: Bool = false) {
        self.type = type
        self.pilot = pilot
        self.skillPlanSkill = skillPlanSkill
        self.editMode = editMode
    }
    
    init(type: SDEInvType, pilot: Pilot?, targetLevel: Int?, editMode: Bool = false) {
        self.type = type
        self.pilot = pilot
        self.targetLevel = targetLevel
        self.editMode = editMode
    }
    
    @State private var isActionsSheetPresented = false
    @State private var isTypeInfoActive = false
    @Environment(\.self) private var environment
    
    private func actionSheet(_ levels: Range<Int>) -> ActionSheet {
        let buttons = levels.map { level in
            ActionSheet.Button.default(Text("Traint to level \(String(roman: level))")) {
                guard let pilot = self.pilot else {return}
                let trainingQueue = TrainingQueue(pilot: pilot)
                trainingQueue.add(self.type, level: level)
                let skillPlan = self.sharedState.account?.activeSkillPlan
                skillPlan?.add(trainingQueue)
                NotificationCenter.default.post(name: .didUpdateSkillPlan, object: skillPlan)
            }
        }
        return ActionSheet(title: Text("Add to Skill Plan"), message: nil, buttons: buttons + [.default(Text("Skill Info")) { self.isTypeInfoActive = true } ,.cancel()])
    }
    
    var body: some View {
        let trainedLevel = pilot?.trainedSkills[Int(type.typeID)]?.trainedSkillLevel ?? 0
        let canTrain: Range<Int>?
        if let skillPlan = sharedState.account?.activeSkillPlan, editMode && trainedLevel < 5  {
            let from = (skillPlan.skills?.allObjects as? [SkillPlanSkill])?.filter{$0.typeID == type.typeID}.map{Int($0.level)}.max() ?? trainedLevel
            canTrain = (from + 1)..<6
        }
        else {
            canTrain = nil
        }
        
        let body = //NavigationLink(destination: TypeInfo(type: type), isActive: $isTypeInfoActive) {
            SkillCellBody(type: type, pilot: pilot, skillQueueItem: skillQueueItem, skillPlanSkill: skillPlanSkill, targetLevel: targetLevel)
        //}
        
        return Group {
            if canTrain != nil {
                Button(action: {self.isActionsSheetPresented = true}) {
                    body
                }.buttonStyle(PlainButtonStyle())
            }
            else {
                NavigationLink(destination: TypeInfo(type: type).modifier(ServicesViewModifier(environment: environment, sharedState: sharedState)), isActive: $isTypeInfoActive) {
                    body
                }
            }
        }.actionSheet(isPresented: $isActionsSheetPresented) {
            self.actionSheet(canTrain ?? 0..<0)
        }
    }
}


struct SkillCellBody: View {
    var type: SDEInvType
    var pilot: Pilot?
    var skillQueueItem: Pilot.SkillQueueItem?
    var skillPlanSkill: SkillPlanSkill?
    var targetLevel: Int?

    private static var counter: Int = 0
    private static func getID() -> Int {
        defer {counter += 1}
        return counter
    }
    
    

    var body: some View {
        let skill = Pilot.Skill(type: type)
        
        let typeID = Int(type.typeID)
        let trainedSkill = pilot?.trainedSkills[typeID]

        let trainedLevel = trainedSkill?.trainedSkillLevel ?? 0
        let level = skillPlanSkill.map{Int($0.level)} ?? skillQueueItem?.queuedSkill.finishedLevel ?? targetLevel ?? trainedSkill?.trainedSkillLevel ?? 0

        let rank = Int(skill?.rank ?? 0)
        let sps = skill?.skillPointsPerSecond(with: pilot?.attributes ?? .default) ?? 0
        let sph = UnitFormatter.localizedString(from: Int((sps * 3600).rounded()), unit: .none, style: .long)
        
        let trainingTime: TimeInterval
        var progress: Float?
        
        let targetLevel: Int
        let isActive: Bool
        var sp: Int?
        var endSP: Int?
        
        if let skillQueueItem = skillQueueItem {
            targetLevel = skillQueueItem.queuedSkill.finishedLevel
            isActive = skillQueueItem.isActive
            trainingTime = skillQueueItem.trainingTimeToLevelUp(with: pilot?.attributes ?? .default)
            progress = skillQueueItem.trainingProgress
            sp = skillQueueItem.skillPoints
            endSP = skillQueueItem.skill.skillPoints(at: skillQueueItem.queuedSkill.finishedLevel)
        }
        else if let skillPlanSkill = skillPlanSkill {
            targetLevel = Int(skillPlanSkill.level)
            isActive = false
            if let skill = skill {
                sp = max(skill.skillPoints(at: Int(skillPlanSkill.level - 1)), Int(trainedSkill?.skillpointsInSkill ?? 0))
                endSP = skill.skillPoints(at: Int(skillPlanSkill.level))
                trainingTime = TrainingQueue.Item(skill: skill, targetLevel: Int(skillPlanSkill.level), startSP: sp).trainingTime(with: pilot?.attributes ?? .default)
            }
            else {
                trainingTime = 0
            }
        }
        else if let target = self.targetLevel {
            targetLevel = target
            isActive = false
            if let skill = skill {
                trainingTime = trainedLevel < 5 ? TrainingQueue.Item(skill: skill, targetLevel: targetLevel, startSP: trainedSkill.map{Int($0.skillpointsInSkill)}).trainingTime(with: pilot?.attributes ?? .default) : 0
            }
            else {
                trainingTime = 0
            }
        }
        else {
            let queuedSkills = pilot?.skillQueue.filter{$0.queuedSkill.skillID == typeID}
            isActive = queuedSkills?.contains{$0.isActive} ?? false
            targetLevel = queuedSkills?.map{$0.queuedSkill.finishedLevel}.max() ?? 0
            if let skill = queuedSkills?.first, (trainedSkill?.trainedSkillLevel ?? 0) == skill.queuedSkill.finishedLevel - 1 {
                sp = skill.skillPoints
                endSP = skill.skill.skillPoints(at: skill.queuedSkill.finishedLevel)
                trainingTime = skill.trainingTimeToLevelUp(with: pilot?.attributes ?? .default)
                progress = skill.trainingProgress
            }
            else if let skill = skill {
                trainingTime = trainedLevel < 5 ? TrainingQueue.Item(skill: skill, targetLevel: trainedLevel + 1, startSP: trainedSkill.map{Int($0.skillpointsInSkill)}).trainingTime(with: pilot?.attributes ?? .default) : 0
            }
            else {
                trainingTime = 0
            }

        }

        let skillPoints: Text
        if let sp = sp, let endSP = endSP {
            let a = UnitFormatter.localizedString(from: sp, unit: .skillPoints, style: .long)
            let b = UnitFormatter.localizedString(from: endSP, unit: .skillPoints, style: .long)
            skillPoints = Text("\(a) / \(b) (\(sph) SP/h)")
        }
        else {
            skillPoints = Text("\(sph) SP/h")
        }

        
//        let progressView = progress.map{progress in ProgressView(progress: progress, progressTintColor: Color(.placeholderText).opacity(0.5), progressTrackColor: .clear, borderColor: Color(.placeholderText))}
        let progressView = progress.map{progress in ProgressView(progress: progress).accentColor(.skyBlueBackground)}
        
        return HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(type.typeName ?? "") + Text(" (x\(rank))")
                skillPoints.modifier(SecondaryLabelModifier())
            }.lineLimit(1)
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                HStack {
                    Text("LEVEL \(level > 0 ? String(roman: level) : "0")")
                    HStack(spacing: 1) {
                        ForEach(0..<5) { i in
                            if isActive && i == trainedLevel {
                                FlashigRectangle().frame(width: 8, height: 4)
                                    .id(Self.getID()) //Animation hack
                            }
                            else {
                                Rectangle().frame(width: 8, height: 4).opacity(i < trainedLevel ? 1 : i < targetLevel ? 0.3 : 0.0)
                            }
                        }
                    }.padding(1.5).border(Color.secondary)
                }
                if trainedLevel == 5 {
                    Text("COMPLETED")
                }
                else if trainingTime > 0 {
                    if isActive {
                        Text("\(TimeIntervalFormatter.localizedString(from: trainingTime, precision: .minutes)) (\(Int((progress ?? 0) * 100))%)")
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)
                            .background(progressView)
                    }
                    else {
                        Text("\(TimeIntervalFormatter.localizedString(from: trainingTime, precision: .minutes))")
                    }
                }
                else {
                    Text(" ")
                }
            }.modifier(SecondaryLabelModifier()).layoutPriority(1)
        }
    }
}

private struct FlashigRectangle: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .opacity(self.isAnimating ? 0.0 : 1.0)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.0).repeatForever()) {
                    self.isAnimating.toggle()
                }
        }
    }
}

#if DEBUG
struct SkillCell_Previews: PreviewProvider {
    static var previews: some View {
        let type = try! AppDelegate.sharedDelegate.persistentContainer.viewContext
            .from(SDEInvType.self)
            .filter(/\SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue)
            .first()!
        var pilot = Pilot.empty
        let skill = Pilot.Skill(type: type)!
        pilot.trainedSkills[Int(type.typeID)] = ESI.Skill(activeSkillLevel: 1, skillID: Int(type.typeID), skillpointsInSkill: Int64(skill.skillPoints(at: 1)), trainedSkillLevel: 1)
        pilot.skillQueue.append(Pilot.SkillQueueItem(skill: skill, queuedSkill: ESI.SkillQueueItem(finishDate: Date(timeIntervalSinceNow: 3600),
                                                                                                   finishedLevel: 2,
                                                                                                   levelEndSP: skill.skillPoints(at: 2),
                                                                                                   levelStartSP: skill.skillPoints(at: 1),
                                                                                                   queuePosition: 0,
                                                                                                   skillID: Int(type.typeID),
                                                                                                   startDate: Date(timeIntervalSinceNow: -3600),
                                                                                                   trainingStartSP: skill.skillPoints(at: 1))))
        
        pilot.skillQueue.append(Pilot.SkillQueueItem(skill: skill, queuedSkill: ESI.SkillQueueItem(finishDate: Date(timeIntervalSinceNow: 3600 * 2),
                                                                                                   finishedLevel: 3,
                                                                                                   levelEndSP: skill.skillPoints(at: 3),
                                                                                                   levelStartSP: skill.skillPoints(at: 2),
                                                                                                   queuePosition: 1,
                                                                                                   skillID: Int(type.typeID),
                                                                                                   startDate: Date(timeIntervalSinceNow: 3600),
                                                                                                   trainingStartSP: skill.skillPoints(at: 2))))

        let skillPlanSkill = SkillPlanSkill(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        skillPlanSkill.typeID = type.typeID
        skillPlanSkill.level = 3
        return NavigationView {
            List {
            SkillCell(type: type, pilot: pilot)
            SkillCell(type: type, pilot: nil)
            SkillCell(type: type, pilot: pilot, skillQueueItem: pilot.skillQueue.first!)
            SkillCell(type: type, pilot: pilot, skillQueueItem: pilot.skillQueue.last!)
            SkillCell(type: type, pilot: pilot, skillPlanSkill: skillPlanSkill)
        }
        }.listStyle(GroupedListStyle())
        .environmentObject(SharedState.testState())
    }
}
#endif
