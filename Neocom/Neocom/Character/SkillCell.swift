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

extension AnyTransition {
    static func repeating<T: ViewModifier>(from: T, to: T, duration: Double = 1) -> AnyTransition {
       .asymmetric(
            insertion: AnyTransition
                .modifier(active: from, identity: to)
                .animation(Animation.easeInOut(duration: duration).repeatForever())
                .combined(with: .opacity),
            removal: .opacity
        )
    }
}

struct Opacity: ViewModifier {
    private let opacity: Double
    init(_ opacity: Double) {
        self.opacity = opacity
    }

    func body(content: Content) -> some View {
        content.opacity(opacity)
    }
}

struct SkillCell: View {
    var type: SDEInvType
    var pilot: Pilot?
    var skillQueueItem: Pilot.SkillQueueItem?
    var skillPlanSkill: SkillPlanSkill?

    private static var counter: Int = 0
    private static func getID() -> Int {
        defer {counter += 1}
        return counter
    }
    
    init(type: SDEInvType, pilot: Pilot?) {
        self.type = type
        self.pilot = pilot
    }
    
    init(type: SDEInvType, pilot: Pilot?, skillQueueItem: Pilot.SkillQueueItem) {
        self.type = type
        self.pilot = pilot
        self.skillQueueItem = skillQueueItem
    }

    init(type: SDEInvType, pilot: Pilot?, skillPlanSkill: SkillPlanSkill) {
        self.type = type
        self.pilot = pilot
        self.skillPlanSkill = skillPlanSkill
    }

    var body: some View {
        let skill = Pilot.Skill(type: type)
        
        let typeID = Int(type.typeID)
        let trainedSkill = pilot?.trainedSkills[typeID]

        let trainedLevel = trainedSkill?.trainedSkillLevel ?? 0
        let level = skillQueueItem?.queuedSkill.finishedLevel ?? trainedSkill?.trainedSkillLevel

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

        
        let progressView = progress.map{progress in ProgressView(progress: progress, progressTintColor: Color(.placeholderText).opacity(0.5), progressTrackColor: .clear, borderColor: .clear)}
        
        return NavigationLink(destination: TypeInfo(type: type)) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(type.typeName ?? "") + Text(" (x\(rank))")
                    skillPoints.modifier(SecondaryLabelModifier())
                }.lineLimit(1)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    HStack {
                        level.map{Text("LEVEL \(String(roman: $0))")}
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
                            Text("\(TimeIntervalFormatter.localizedString(from: trainingTime, precision: .minutes)) (\(Int((progress ?? 0) * 100))%)").background(progressView)
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
            .padding(.horizontal, 15)
            .padding(.vertical, 4)
            .listRowInsets(EdgeInsets())
            
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

struct SkillCell_Previews: PreviewProvider {
    static var previews: some View {
        let type = try! AppDelegate.sharedDelegate.persistentContainer.viewContext
            .from(SDEInvType.self)
            .filter(Expressions.keyPath(\SDEInvType.group?.category?.categoryID) == SDECategoryID.skill.rawValue)
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
        return List {
            SkillCell(type: type, pilot: pilot)
            SkillCell(type: type, pilot: nil)
            SkillCell(type: type, pilot: pilot, skillQueueItem: pilot.skillQueue.first!)
            SkillCell(type: type, pilot: pilot, skillQueueItem: pilot.skillQueue.last!)
            SkillCell(type: type, pilot: pilot, skillPlanSkill: skillPlanSkill)
        }.listStyle(GroupedListStyle())
    }
}
