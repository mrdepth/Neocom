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

enum LanguageID: String, CaseIterable {
    case en = "SDE_en"
    case de = "SDE_de"
    case es = "SDE_es"
    case fr = "SDE_fr"
    case it = "SDE_it"
    case ja = "SDE_ja"
    case ru = "SDE_ru"
    case zh = "SDE_zh"
    case ko = "SDE_ko"
    
    static let `default` = LanguageID.en
}

class Storage: ObservableObject {
    static var sharedStorage: Storage {
        AppDelegate.sharedDelegate.storage
    }
    
    @Published var sde: BundleResource {
        didSet {
            guard sde.isAvailable() else {return}
            guard let url = Bundle.main.url(forResource: sde.tag, withExtension: "sqlite") else {return}
            
            guard let store = persistentContainer.persistentStoreCoordinator.persistentStores.first(where: {$0.configurationName == "SDE"}) else {return}
            persistentContainer.persistentStoreCoordinator.setURL(url, for: store)
            currentLanguagID = LanguageID(rawValue: sde.tag) ?? .default
            languageSetting = currentLanguagID.rawValue
        }
    }
    
    @Published private(set) var currentLanguagID: LanguageID
    @UserDefault(key: .languageID) private var languageSetting: String = LanguageID.default.rawValue
    
    func supportedLanguages() -> [BundleResource] {
        LanguageID.allCases.map {
            sde.tag == $0.rawValue ? sde : BundleResource(tag: $0.rawValue)
        }
    }
    
    init() {
        let setting = UserDefault(wrappedValue: LanguageID.default.rawValue, key: .languageID)
        _languageSetting = setting
        let sde = BundleResource(tag: setting.wrappedValue)
        self.sde = sde
        currentLanguagID = sde.isAvailable() ? LanguageID(rawValue: sde.tag) ?? .default : .default
    }

    var managedObjectModel: NSManagedObjectModel {
//        NSManagedObjectModel.mergedModel(from: nil)!
        let sdeModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "SDE", withExtension: "momd")!)!
        let cloudModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Cloud", withExtension: "momd")!)!
        let localMode = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Local", withExtension: "momd")!)!
        return NSManagedObjectModel(byMerging: [sdeModel, cloudModel, localMode])!
    }

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "Neocom", managedObjectModel: managedObjectModel)
        
        let resource = sde.isAvailable() ? sde.tag : "SDE_en"
        
        let url = Bundle.main.url(forResource: resource, withExtension: "sqlite") ?? Bundle.main.url(forResource: "SDE_en", withExtension: "sqlite")
        let sde = NSPersistentStoreDescription(url: url!)
        sde.configuration = "SDE"
        sde.isReadOnly = true
        sde.shouldMigrateStoreAutomatically = false
        
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        let storage = NSPersistentStoreDescription(url: baseURL.appendingPathComponent("cloud.sqlite"))
        storage.configuration = "Cloud"
        storage.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.shimanski.neocom")
        storage.shouldMigrateStoreAutomatically = true
        
        let cache = NSPersistentStoreDescription(url: baseURL.appendingPathComponent("local.sqlite"))
        cache.configuration = "Local"
        
        container.persistentStoreDescriptions = [sde, storage, cache]
        
        container.loadPersistentStores { (_, error) in
            if let error = error {
                print(error)
            }
        }
        container.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
        
//        do {
//            try container.initializeCloudKitSchema(options: [.printSchema])
//        }
//        catch {
//            print(error)
//        }
        
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                if let error = error as? CocoaError, let conflicts = error.userInfo[NSPersistentStoreSaveConflictsErrorKey] as? [NSMergeConflict] {
                    do {
                        try NSMergePolicy(merge: .overwriteMergePolicyType).resolve(mergeConflicts: conflicts)
                        try context.save()
                    }
                    catch {
                        #if DEBUG
                        let nserror = error as NSError
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                        #endif
                    }
                }
                else {
                    #if DEBUG
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    #endif
                }
            }
        }
    }
    
}

/*class Storage: NSPersistentCloudKitContainer {
    init() {
        let storageModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Storage", withExtension: "momd")!)!
        let sdeModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "SDE", withExtension: "momd")!)!
        let model = NSManagedObjectModel(byMerging: [storageModel, sdeModel])!
        super.init(name: "Neocom", managedObjectModel: model)
        let sde = NSPersistentStoreDescription(url: Bundle.main.url(forResource: "SDE_en", withExtension: "sqlite")!)
        sde.configuration = "SDE"
        sde.isReadOnly = true
        sde.shouldMigrateStoreAutomatically = false
        
        let storage = NSPersistentStoreDescription(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!).appendingPathComponent("stora.sqlite"))
        storage.configuration = "Storage"
//        storage.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.shimanski.neocom")
        persistentStoreDescriptions = [sde, storage]
    }
}*/

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
    
    func verifyCredentials(_ scopes: [ESI.Scope]) -> Bool {
        guard !scopes.isEmpty else {return true}
        let current = self.scopes?.compactMap {($0 as? Scope)?.name}.compactMap {ESI.Scope($0)} ?? []
        return Set(scopes).isSubset(of: current)
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

extension Contact {
    var recipientType: ESI.RecipientType? {
        category.flatMap{ESI.RecipientType(rawValue: $0)}
    }
}

extension Loadout {
    var ship: Ship? {
        get {
            LoadoutTransformer().reverseTransformedValue(data?.data) as? Ship
        }
        set {
            let loadout = LoadoutTransformer().transformedValue(newValue) as? Data
            guard data?.data != loadout else {return}
            data?.data = loadout
        }
    }
}
