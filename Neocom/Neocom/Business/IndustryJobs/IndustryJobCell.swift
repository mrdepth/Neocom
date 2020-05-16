//
//  IndustryJobCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import EVEAPI

struct IndustryJobCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var job: ESI.IndustryJobs.Element
    var locations: [Int64: EVELocation]
    
    func content(_ type: SDEInvType?) -> some View {
        let currentStatus = job.currentStatus
        let t = job.endDate.timeIntervalSinceNow
        
        let endDate = {
            DateFormatter.localizedString(from: self.job.endDate, dateStyle: .short, timeStyle: .short)
        }
        
        let activity = try? managedObjectContext.from(SDERamActivity.self).filter(/\SDERamActivity.activityID == Int32(job.activityID)).first()

        var status: Text
        let progress: Float
        switch currentStatus {
        case .active:
            progress = 1.0 - Float(t / TimeInterval(job.duration))
            status = Text("\(TimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes)) (\(Int(progress * 100))%)")
        case .cancelled:
            status = Text("cancelled \(endDate())")
            progress = 0
        case .delivered:
            status = Text("delivered \(endDate())")
            progress = 1
        case .paused:
            status = Text("paused \(endDate()))")
            progress = 0
        case .ready:
            status = Text("ready \(endDate()))")
            progress = 1
        case .reverted:
            status = Text("reverted \(endDate()))")
            progress = 0
        }
        
        if let activity = activity?.activityName {
            status = Text(activity).fontWeight(.semibold) + Text(": ") + status
        }
        let isActive = currentStatus == .active || currentStatus == .ready
//        .foregroundColor(currentStatus == .active || currentStatus == .ready ? .primary : .secondary)
        
        return VStack(alignment: .leading) {
            HStack {
                type.map{Icon($0.image).cornerRadius(4)}
                VStack(alignment: .leading) {
                    ((type?.typeName).map {Text($0)} ?? Text("Unknown Type")).foregroundColor(.accentColor)
                    Text(locations[job.outputLocationID] ?? locations[job.stationID] ?? .unknown(job.outputLocationID)).modifier(SecondaryLabelModifier())
                }
            }
            status.padding(.horizontal).frame(maxWidth: .infinity).font(.subheadline).foregroundColor(.white)
                .background(ProgressView(progress: progress).accentColor(.skyBlue))
            HStack(spacing: 24) {
                Text("Jub Runs: ").fontWeight(.semibold).foregroundColor(.accentColor)
                    + Text("\(job.runs)")
                Text("Runs per Copy: ").fontWeight(.semibold).foregroundColor(.accentColor)
                    + Text("\(job.licensedRuns ?? 0)")
            }.modifier(SecondaryLabelModifier())
        }.accentColor(isActive ? .primary : .secondary)
    }
    
    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(job.blueprintTypeID)).first()
        
        return Group {
            if type != nil {
                NavigationLink(destination: TypeInfo(type: type!)) {
                    content(type)
                }
            }
            else {
                content(nil)
            }
        }
    }
}

struct IndustryJobCell_Previews: PreviewProvider {
    static var previews: some View {
        let solarSystem = try! Storage.sharedStorage.persistentContainer.viewContext.from(SDEMapSolarSystem.self).first()!
        let location = EVELocation(solarSystem: solarSystem, id: Int64(solarSystem.solarSystemID))

        let job = ESI.IndustryJobs.Element(activityID: 1,
                                           blueprintID: 645,
                                           blueprintLocationID: location.id,
                                           blueprintTypeID: 645,
                                           completedCharacterID: 1554561480,
                                           completedDate: Date(timeIntervalSinceNow: 3600),
                                           cost: 1000,
                                           duration: 3600 * 10,
                                           endDate: Date(timeIntervalSinceNow: 3600 * 5),
                                           facilityID: 0,
                                           installerID: 1554561480,
                                           jobID: 1,
                                           licensedRuns: 10,
                                           outputLocationID: location.id,
                                           pauseDate: nil,
                                           probability: 0.5,
                                           productTypeID: 645,
                                           runs: 5,
                                           startDate: Date(timeIntervalSinceNow: -3600 * 2),
                                           stationID: location.id,
                                           status: .active,
                                           successfulRuns: 3)
        
        return NavigationView {
            List {
                IndustryJobCell(job: job, locations: [location.id: location])
            }.listStyle(GroupedListStyle())
//                .colorScheme(.dark)
        }.environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
