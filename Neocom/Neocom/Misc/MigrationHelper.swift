//
//  MigrationHelper.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/7/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import CoreData
import CloudKit
import Expressible
import EVEAPI

class MigrationHelper {
    private var database: CKDatabase
    private var managedObjectContext: NSManagedObjectContext
    
    @Published var isInProgress = true
    
    private var subscription: AnyCancellable?
    
    private static var initializeUnarchiver: Bool = {
        NSKeyedUnarchiver.setClass(LoadoutDescription.self, forClassName: "Neocom.NCFittingLoadout")
        NSKeyedUnarchiver.setClass(LoadoutDescription.Item.self, forClassName: "Neocom.NCFittingLoadoutItem")
        NSKeyedUnarchiver.setClass(LoadoutDescription.Item.Module.self, forClassName: "Neocom.NCFittingLoadoutModule")
        NSKeyedUnarchiver.setClass(LoadoutDescription.Item.Drone.self, forClassName: "Neocom.NCFittingLoadoutDrone")
        //        NSKeyedUnarchiver.setClass(FleetDescription.self, forClassName: "Neocom.NCFleetConfiguration")
        NSKeyedUnarchiver.setClass(ImplantSetDescription.self, forClassName: "Neocom.NCImplantSetData")
        return true
    }()
    
    class func migrate(records: Set<CKRecord>, from database: CKDatabase, to managedObjectContext: NSManagedObjectContext) -> AnyPublisher<Void, Error> {
        _ = initializeUnarchiver
        
        return fetchReferences(from: records, database: database).flatMap { result1 in
            fetchReferences(from: result1.values, database: database).map { result2 in
                result1.merging(result2) {a, _ in a}
            }
        }
        .receive(on: managedObjectContext)
        .map { references in
            for record in records {
                switch record.recordType {
                case "Loadout":
                    migrate(loadout: record, to: managedObjectContext, references: references)
                case "Account":
                    migrate(account: record, to: managedObjectContext, references: references)
                default:
                    break
                }
            }
            if managedObjectContext.hasChanges {
                try? managedObjectContext.save()
            }
        }
        .eraseToAnyPublisher()
    }
    
    class func migrate(loadout record: CKRecord, to managedObjectContext: NSManagedObjectContext, references: [CKRecord.ID: CKRecord]) {
        guard let reference = record["data"] as? CKRecord.Reference,
            let typeID = record["typeID"] as? Int,
            let dataRecord = references[reference.recordID],
            let data = dataRecord["data"] as? Data,
            let decompressed = try? data.decompressed(algorithm: .zlibDefault),
            let description = try? NSKeyedUnarchiver.unarchivedObject(ofClass: LoadoutDescription.self, from: decompressed)
        else {return}
        let ship = Ship(typeID: typeID, name: record["name"] as? String, loadout: description)
        let uuid = record["uuid"] as? String ?? UUID().uuidString
        let loadout = (try? managedObjectContext.from(Loadout.self).filter(/\Loadout.uuid == uuid).first()) ?? {
            let loadout = Loadout(context: managedObjectContext)
            loadout.data = LoadoutData(context: managedObjectContext)
            return loadout
        }()
        loadout.typeID = Int32(typeID)
        loadout.ship = ship
        loadout.uuid = uuid
        loadout.name = ship.name
    }
    
    class func migrate(account record: CKRecord, to managedObjectContext: NSManagedObjectContext, references: [CKRecord.ID: CKRecord]) {
        guard let accessToken = record["accessToken"] as? String,
            let characterID = record["characterID"] as? Int64,
            let characterName = record["characterName"] as? String,
            let expiresOn = record["expiresOn"] as? Date,
            let realm = record["realm"] as? String,
            let refreshToken = record["refreshToken"] as? String,
            let tokenType = record["tokenType"] as? String,
            let uuid = record["uuid"] as? String,
            let scopes = (record["scopes"] as? [CKRecord.Reference]).flatMap({scopes in scopes.compactMap{references[$0.recordID]?["name"] as? String}})
            else {return}
        let token = OAuth2Token(accessToken: accessToken, refreshToken: refreshToken, tokenType: tokenType, expiresOn: expiresOn, characterID: characterID, characterName: characterName, realm: realm, scopes: scopes)
        let account = Account(context: managedObjectContext)
        account.uuid = uuid
        account.oAuth2Token = token
        
        let skillPlans = (record["skillPlans"] as? [CKRecord.Reference]).map{skillPlans in skillPlans.compactMap{references[$0.recordID]}}
        
        skillPlans?.forEach {
            migrate(skillPlan: $0, of: account, to: managedObjectContext, references: references)
        }
    }
    
    class func migrate(skillPlan record: CKRecord, of account: Account, to managedObjectContext: NSManagedObjectContext, references: [CKRecord.ID: CKRecord]) {
        guard let name = record["name"] as? String,
            let skills = (record["skills"] as? [CKRecord.Reference]).map({skills in skills.compactMap({references[$0.recordID]})})
            else {return}
        let skillPlan = SkillPlan(context: managedObjectContext)
        skillPlan.name = name
        skillPlan.account = account
        skills.forEach { record in
            guard let level = record["level"] as? Int,
                let position = record["position"] as? Int,
                let typeID = record["typeID"] as? Int
                else {return}
            let skill = SkillPlanSkill(context: managedObjectContext)
            skill.skillPlan = skillPlan
            skill.level = Int16(level)
            skill.position = Int32(position)
            skill.typeID = Int32(typeID)
        }
    }
    
    class private func fetchReferences<T: Collection>(from records: T, database: CKDatabase) -> AnyPublisher<[CKRecord.ID: CKRecord], Error> where T.Element == CKRecord {
        let ids = records.flatMap { record -> [CKRecord.ID] in
            switch record.recordType {
            case "Account":
                return ((record["skillPlans"] as? [CKRecord.Reference])?.map{$0.recordID} ?? []) +
                    ((record["scopes"] as? [CKRecord.Reference])?.map{$0.recordID} ?? [])
            case "Loadout":
                return (record["data"] as? CKRecord.Reference).map{[$0.recordID]} ?? []
            case "SkillPlan":
                return (record["skills"] as? [CKRecord.Reference])?.map{$0.recordID} ?? []
            default:
                return []
            }
        }
        
        guard !ids.isEmpty else {return Just([:]).setFailureType(to: Error.self).eraseToAnyPublisher()}
        
        return Future { promise in
            let operation = CKFetchRecordsOperation(recordIDs: ids)
            operation.fetchRecordsCompletionBlock = { (result, error) in
                if let result = result, error == nil {
                    
                    promise(.success(result))
                }
                else {
                    promise(.failure(error ?? RuntimeError.unknown))
                }
            }
            database.add(operation)
        }.eraseToAnyPublisher()
    }
    
    init(records: [CKRecord], from database: CKDatabase, to managedObjectContext: NSManagedObjectContext) {
        self.database = database
        self.managedObjectContext = managedObjectContext
        
        subscription = fetchReferences(from: records).flatMap { result1 in
            self.fetchReferences(from: result1.values).map { result2 in
                result1.merging(result2) {a, _ in a}
            }
        }
        .receive(on: managedObjectContext)
        .sink(receiveCompletion: { [weak self] _ in
            self?.isInProgress = false
        }) { references in
            for record in records {
                switch record.recordType {
                case "Loadout":
                    guard let reference = record["data"] as? CKRecord.Reference,
                        let dataRecord = references[reference.recordID],
                        let data = dataRecord["data"] as? Data,
                        let description = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? LoadoutDescription
                    else {break}
                default:
                    break
                }
            }
        }
    }
    
    private func fetchReferences<T: Collection>(from records: T) -> AnyPublisher<[CKRecord.ID: CKRecord], Error> where T.Element == CKRecord {
        let ids = records.flatMap { record -> [CKRecord.ID] in
            switch record.recordType {
            case "Account":
                return ((record["skillPlans"] as? [CKRecord.Reference])?.map{$0.recordID} ?? []) +
                    ((record["scopes"] as? [CKRecord.Reference])?.map{$0.recordID} ?? [])
            case "Loadout":
                return (record["data"] as? [CKRecord.Reference])?.map{$0.recordID} ?? []
            case "SkillPlan":
                return (record["skills"] as? [CKRecord.Reference])?.map{$0.recordID} ?? []
            default:
                return []
            }
        }
        
        guard !ids.isEmpty else {return Just([:]).setFailureType(to: Error.self).eraseToAnyPublisher()}
        
        return Future { promise in
            let operation = CKFetchRecordsOperation(recordIDs: ids)
            operation.fetchRecordsCompletionBlock = { (result, error) in
                if let result = result, error == nil {
                    
                    promise(.success(result))
                }
                else {
                    promise(.failure(error ?? RuntimeError.unknown))
                }
            }
            self.database.add(operation)
        }.eraseToAnyPublisher()
        
    }
}
