//
//  AccountCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct AccountCellContent: View {
    struct Subject {
        let name: String
        let image: Image?
    }
    struct Skill {
        var name: String
        var level: Int
        var trainingTime: TimeInterval
    }
    
    var character: Subject?
    var corporation: Subject?
    var alliance: Subject?
    
    var ship: String?
    var location: String?
    var sp: Int64?
    var isk: Int64?
    var skill: Skill?
    var skillQueue: Int?
    
    var body: some View {
        VStack {
            HStack {
                Avatar(image: character?.image).frame(width: 64, height: 64)
                
                VStack(alignment: .leading, spacing: 0) {
                    (character?.name).map{Text($0)}.font(.title)
                    HStack {
                        corporation?.image?.resizable().frame(width: 24, height: 24)
                        (corporation?.name).map{Text($0)}
                        (alliance?.name).map{ name in
                            Group{
                                Text("/")
                                //                                allianceImage?.resizable().frame(width: 24, height: 24)
                                Text(name)
                            }
                        }
                    }.foregroundColor(.secondary)
                }
                Spacer()
            }
            HStack(alignment: .top) {
                HStack {
                    VStack(alignment: .trailing) {
                        Text("SP:")
                        Text("ISK:")
                    }.foregroundColor(.skyBlue)
                    VStack(alignment: .leading) {
                        sp.map{Text(UnitFormatter.localizedString(from: $0, unit: .skillPoints, style: .short))}
                        isk.map{Text(UnitFormatter.localizedString(from: $0, unit: .skillPoints, style: .short))}
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        ship.map{Text($0)}
                        location.map{Text($0)}.foregroundColor(.secondary)
                    }
                    HStack{
                        skill.map { skill in
                            Group {
                                Text(skill.name + " ") + Text(String(roman: skill.level)).foregroundColor(.skyBlue)
                                Spacer()
                                Text(TimeIntervalFormatter.localizedString(from: skill.trainingTime, precision: .minutes))
                            }
                        }
                    }.padding(.horizontal).background(ProgressView(progress: 0.9))
                    skillQueue.map{
                        $0 > 0 ? Text("\($0) skills in queue") : Text("Skill queue is empty")
                    }
                }
                Spacer(minLength: 0)
            }
        }.padding().font(.subheadline).background(Color(UIColor.systemGroupedBackground)).lineLimit(1)
    }
}

struct AccountCellContent_Previews: PreviewProvider {
    static var previews: some View {
        let row = AccountCellContent(character: .init(name: "Artem Valiant", image: Image("character")),
                                     corporation: .init(name: "Necrorise Squadron", image: Image("corporation")),
                                     alliance: .init(name: "Red Alert", image: Image("alliance")),
                                     ship: "Dominix",
                                     location: "Rens VII, Moon 8",
                                     sp: 1000,
                                     isk: 1000,
                                     skill: .init(name: "Battleship", level: 5, trainingTime: 3600 * 48 - 1),
                                     skillQueue: 5)
        return VStack {
            row.colorScheme(.light)
            row.colorScheme(.dark)
            AccountCellContent(character: nil,
            corporation: nil,
            alliance: nil,
            ship: nil,
            location: nil,
            sp: nil,
            isk: nil,
            skill: nil,
            skillQueue: nil)
        }
    }
}
