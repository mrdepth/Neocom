//
//  IndustryJobs.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct IndustryJobs: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState

    @ObservedObject var orders: Lazy<IndustryJobsData, Account> = Lazy()

    var body: some View {
        let result = sharedState.account.map { account in
            self.orders.get(account, initial: IndustryJobsData(esi: sharedState.esi, characterID: account.characterID, managedObjectContext: managedObjectContext))
        }
        let jobs = (result?.result?.value).map{$0.active + $0.finished}
        
        let list = List {
            if jobs != nil {
                IndustryJobsContent(jobs: jobs!, locations: result?.result?.value?.locations ?? [:])
            }
        }.listStyle(GroupedListStyle())
            .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay((result?.result?.error).map{Text($0)})
            .overlay(jobs?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        
        return Group {
            if result != nil {
                list.onRefresh(isRefreshing: Binding(result!, keyPath: \.isLoading)) {
                    result?.update(cachePolicy: .reloadIgnoringLocalCacheData)
                }
            }
            else {
                list
            }
        }
        .navigationBarTitle(Text("Industry Jobs"))

    }
}

struct IndustryJobsContent: View {
    var jobs: ESI.IndustryJobs
    var locations: [Int64: EVELocation]
    
    var body: some View {
        ForEach(jobs, id: \.jobID) { job in
            IndustryJobCell(job: job, locations: self.locations)
        }
    }
}

struct IndustryJobs_Previews: PreviewProvider {
    static var previews: some View {
        let solarSystem = try! AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEMapSolarSystem.self).first()!
        let location = EVELocation(solarSystem: solarSystem, id: Int64(solarSystem.solarSystemID))
        
        
        let jobs = (0..<100).map { i in
            ESI.IndustryJobs.Element(activityID: 1,
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
                                     jobID: i,
                                     licensedRuns: 10,
                                     outputLocationID: location.id,
                                     pauseDate: nil,
                                     probability: 0.5,
                                     productTypeID: 645,
                                     runs: 5,
                                     startDate: Date(timeIntervalSinceNow: -3600 * TimeInterval(i) * 3),
                                     stationID: location.id,
                                     status: .active,
                                     successfulRuns: 3)
        }
        
        return NavigationView {
//            IndustryJobs()
            List {
                IndustryJobsContent(jobs: jobs, locations: [location.id: location])
            }.listStyle(GroupedListStyle())
                .navigationBarTitle(Text("Industry Jobs"))
            
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(SharedState.testState())
    }
}
