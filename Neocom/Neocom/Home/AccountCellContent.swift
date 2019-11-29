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
    var isk: Double?
    var skill: Skill?
    var skillQueue: Int?
    
    var body: some View {
        VStack {
            HStack(spacing: 15) {
                Avatar(image: character?.image).frame(width: 64, height: 64)
                
                VStack(alignment: .leading, spacing: 0) {
                    (character?.name).map{Text($0)}.font(.title)
                    HStack {
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
            HStack(alignment: .top, spacing: 15) {
                HStack {
                    VStack(alignment: .trailing) {
                        Text("SP:")
                        Text("ISK:")
                    }.foregroundColor(.skyBlue)
                    VStack(alignment: .leading) {
                        Text(sp.map{UnitFormatter.localizedString(from: $0, unit: .none, style: .short)} ?? "")
                        Text(isk.map{UnitFormatter.localizedString(from: $0, unit: .none, style: .short)} ?? "")
                    }
                }.frame(minWidth: 64)
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(ship ?? "")
                        Text(location ?? "").foregroundColor(.secondary)
                    }
                    HStack{
                        Text(skill.map{skill in "\(skill.name) \(String(roman: skill.level))"} ?? " ")
                        Spacer()
                        Text(skill.map{skill in TimeIntervalFormatter.localizedString(from: skill.trainingTime, precision: .minutes)} ?? " ")
                    }.padding(.horizontal).background(ProgressView(progress: 0.5).accentColor(Color(.systemGray2)))
                    Text(skillQueue.map{$0 > 0 ? "\($0) skills in queue" : "Skill queue is empty"} ?? "")
                }
                Spacer(minLength: 0)
            }
        }
            .font(.subheadline)
            .lineLimit(1)
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
                                     skillQueue: 5).padding()
        return VStack {
            row.background(Color(UIColor.systemGroupedBackground)).colorScheme(.light)
            row.background(Color(UIColor.systemGroupedBackground)).colorScheme(.dark)
            AccountCellContent(character: nil,
            corporation: nil,
            alliance: nil,
            ship: nil,
            location: nil,
            sp: nil,
            isk: nil,
            skill: nil,
            skillQueue: nil).padding().background(Color(UIColor.systemGroupedBackground))
        }
    }
}
