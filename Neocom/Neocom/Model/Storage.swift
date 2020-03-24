//
//  Storage.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import EVEAPI
import Expressible
import SwiftUI
import Dgmpp

class Storage: NSPersistentCloudKitContainer {
    init() {
        let storageModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Storage", withExtension: "momd")!)!
        let sdeModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "SDE", withExtension: "momd")!)!
        let model = NSManagedObjectModel(byMerging: [storageModel, sdeModel])!
        super.init(name: "Neocom", managedObjectModel: model)
        let sde = NSPersistentStoreDescription(url: Bundle.main.url(forResource: "SDE", withExtension: "sqlite")!)
        sde.configuration = "SDE"
        sde.isReadOnly = true
        sde.shouldMigrateStoreAutomatically = false
        
        let storage = NSPersistentStoreDescription(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!).appendingPathComponent("stora.sqlite"))
        storage.configuration = "Storage"
//        storage.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.shimanski.neocom")
        persistentStoreDescriptions = [sde, storage]
    }
}

extension NSManagedObjectContext {
	func newBackgroundContext() -> NSManagedObjectContext {
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		context.parent = self
		return context
	}
}

extension Account {
    
    convenience init(token: OAuth2Token, context: NSManagedObjectContext) {
        self.init(context: context)
        oAuth2Token = token
    }
    
    var oAuth2Token: OAuth2Token? {
        get {
            let scopes = (self.scopes as? Set<Scope>)?.compactMap {
                return $0.name
                } ?? []
            guard let accessToken = accessToken,
                let refreshToken = refreshToken,
                let tokenType = tokenType,
                let characterName = characterName,
                let realm = realm else {return nil}
            
            let token = OAuth2Token(accessToken: accessToken, refreshToken: refreshToken, tokenType: tokenType, expiresOn: expiresOn as Date? ?? Date.distantPast, characterID: characterID, characterName: characterName, realm: realm, scopes: scopes)
            return token
        }
        set {
            guard let managedObjectContext = managedObjectContext else {return}
            
            if let token = newValue {
                if accessToken != token.accessToken {accessToken = token.accessToken}
                if refreshToken != token.refreshToken {refreshToken = token.refreshToken}
                if tokenType != token.tokenType {tokenType = token.tokenType}
                if characterID != token.characterID {characterID = token.characterID}
                if characterName != token.characterName {characterName = token.characterName}
                if realm != token.realm {realm = token.realm}
                if expiresOn != token.expiresOn {expiresOn = token.expiresOn}
                let newScopes = Set<String>(token.scopes)
                
                let toInsert: Set<String>
                if var scopes = self.scopes as? Set<Scope> {
                    let toDelete = scopes.filter {
                        guard let name = $0.name else {return true}
                        return !newScopes.contains(name)
                    }
                    for scope in toDelete {
                        managedObjectContext.delete(scope)
                        scopes.remove(scope)
                    }
                    
                    toInsert = newScopes.symmetricDifference(scopes.compactMap {return $0.name})
                }
                else {
                    toInsert = newScopes
                }
                
                for name in toInsert {
                    let scope = Scope(context: managedObjectContext)
                    scope.name = name
                    scope.account = self
                }
            }
        }
    }

    var activeSkillPlan: SkillPlan? {
        if let skillPlan = (try? managedObjectContext?.from(SkillPlan.self).filter(/\SkillPlan.account == self && /\SkillPlan.isActive == true).first()) ?? nil {
            return skillPlan
        }
        else if let skillPlan = skillPlans?.anyObject() as? SkillPlan {
            skillPlan.isActive = true
            return skillPlan
        }
        else if let managedObjectContext = managedObjectContext {
            let skillPlan = SkillPlan(context: managedObjectContext)
            skillPlan.isActive = true
            skillPlan.account = self
            skillPlan.name = NSLocalizedString("Default", comment: "")
            return skillPlan
        }
        else {
            return nil
        }
    }
}

fileprivate struct Pair<A, B> {
    var a: A
    var b: B
    
    init(_ a: A, _ b: B) {
        self.a = a
        self.b = b
    }
}

extension Pair: Equatable where A: Equatable, B: Equatable {}
extension Pair: Hashable where A: Hashable, B: Hashable {}


extension SkillPlan {
    func add(_ trainingQueue: TrainingQueue) {
        let skills = self.skills?.allObjects as? [SkillPlanSkill]
        var position: Int32 = (skills?.map{$0.position}.max()).map{$0 + 1} ?? 0
        var queued = (skills?.map{Pair(Int($0.typeID), Int($0.level))}).map{Set($0)} ?? Set()
        
        for i in trainingQueue.queue {
            let key = Pair(i.skill.typeID, i.targetLevel)
            guard !queued.contains(key) else {continue}
            queued.insert(key)
            let skill = SkillPlanSkill(context: managedObjectContext!)
            skill.skillPlan = self
            skill.typeID = Int32(key.a)
            skill.level = Int16(key.b)
            skill.position = position
            position += 1
        }
    }
}


enum DamageType {
    case em
    case thermal
    case kinetic
    case explosive
}

struct Damage {
    var em: Double = 0
    var thermal: Double = 0
    var kinetic: Double = 0
    var explosive: Double = 0
}

func - (lhs: Double, rhs: Damage) -> Damage {
    return Damage(em: lhs - rhs.em,
                  thermal: lhs - rhs.thermal,
                  kinetic: lhs - rhs.kinetic,
                  explosive: lhs - rhs.explosive)
}

extension SkillPlan: Identifiable {
    public var id: NSManagedObjectID {
        return objectID
    }
}

extension Contact {
    var recipientType: ESI.RecipientType? {
        category.flatMap{ESI.RecipientType(rawValue: $0)}
    }
}
