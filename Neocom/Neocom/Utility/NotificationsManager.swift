//
//  NotificationsManager.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import UserNotifications
import EVEAPI
import Combine
import Alamofire
import CoreData
import Expressible

class NotificationsManager {
    
    struct SkillQueueNotificationOptions: OptionSet {
        var rawValue: Int
        static let inactive = SkillQueueNotificationOptions(rawValue: 1 << 0)
        static let oneHour = SkillQueueNotificationOptions(rawValue: 1 << 1)
        static let fourHours = SkillQueueNotificationOptions(rawValue: 1 << 2)
        static let oneDay = SkillQueueNotificationOptions(rawValue: 1 << 3)
        static let skillTrainingComplete = SkillQueueNotificationOptions(rawValue: 1 << 4)
        
        static let `default`: SkillQueueNotificationOptions = [.inactive, .oneHour, .fourHours, .oneDay, .skillTrainingComplete]
    }
    
    let managedObjectContext: NSManagedObjectContext
    @UserDefault(key: .notificationSettigs) private var _skillQueueNotificationOptions: Int = SkillQueueNotificationOptions.default.rawValue
    @UserDefault(key: .notificationsEnabled) private var notificationsEnabled = true
    
    var skillQueueNotificationOptions: SkillQueueNotificationOptions {
        get {
            SkillQueueNotificationOptions(rawValue: _skillQueueNotificationOptions)
        }
        set {
            _skillQueueNotificationOptions = newValue.rawValue
        }
    }
    
    private var observers: [NSObjectProtocol]?
    private var subscriptions = Set<AnyCancellable>()
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        let observer1 = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: nil) { [weak self] (note) in
            self?.managedObjectContextDidSave(note)
        }

        #if targetEnvironment(macCatalyst)
        let observer2 = NotificationCenter.default.addObserver(forName: Notification.Name("NSApplicationDidBecomeActiveNotification"), object: nil, queue: .main) { [weak self] (note) in
            self?.updateIfNeeded()
        }
        #else
        let observer2 = NotificationCenter.default.addObserver(forName: UIScene.didActivateNotification, object: nil, queue: .main) { [weak self] (note) in
            self?.updateIfNeeded()
        }
        #endif

        _notificationsEnabled.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.lastUpdateDate = .distantPast
                self?.updateIfNeeded()
            }
        }.store(in: &subscriptions)
        __skillQueueNotificationOptions.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.lastUpdateDate = .distantPast
                self?.updateIfNeeded()
            }
        }.store(in: &subscriptions)

        observers = [observer1, observer2]
        updateIfNeeded()
    }
    
    private var lastUpdateDate = Date.distantPast
    
    func updateIfNeeded() {
        guard lastUpdateDate.addingTimeInterval(600) < Date() else {return}
        if notificationsEnabled {
            guard let accounts = try? managedObjectContext.from(Account.self).fetch(), !accounts.isEmpty else {return}
            lastUpdateDate = Date()
            let task = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            update(Set(accounts)) { result in
                DispatchQueue.main.async {
                    if case .failure = result {
                        self.lastUpdateDate = .distantPast
                    }
                    UIApplication.shared.endBackgroundTask(task)
                }
            }
        }
        else {
            removeAllRequests()
            lastUpdateDate = Date()
        }
    }
    
    private func removeAllRequests() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getPendingNotificationRequests { (pendingRequests) in
            notificationCenter.removePendingNotificationRequests(withIdentifiers: pendingRequests.map{$0.identifier})
        }
    }
    
    private func update(_ accounts: Set<Account>, completion: ((Subscribers.Completion<AFError>) -> Void)?) {
        guard !accounts.isEmpty else {
            completion?(.finished)
            return
        }

        let notificationCenter = UNUserNotificationCenter.current()
        let notificationOptions = skillQueueNotificationOptions
        
        notificationCenter.getPendingNotificationRequests { (pendingRequests) in
            self.managedObjectContext.perform {
                var pendingRequests = pendingRequests
                
                var subscription: AnyCancellable?
                
                subscription = Publishers.Sequence(sequence: accounts).setFailureType(to: AFError.self)
                    .compactMap{account in account.oAuth2Token.map{(account: account, esi: ESI(token: $0))}}
                    .flatMap{ i in
                        i.esi.characters.characterID(Int(i.account.characterID)).skillqueue().get().map{$0.value}
                            .catch{_ in Empty()}
                            .zip(i.esi.image.character(Int(i.account.characterID), size: .size256).replaceError(with: UIImage()).setFailureType(to: AFError.self))
                            .map{(i.account, $0.0, $0.1)}
                }
                .receive(on: self.managedObjectContext)
                .sink(receiveCompletion: {result in
                    subscription?.cancel()
                    completion?(result)
                    if case .finished = result, !pendingRequests.isEmpty {
                        notificationCenter.removePendingNotificationRequests(withIdentifiers: pendingRequests.map{$0.identifier})
                    }
                    
                }) { (account, skillQueue, image) in
                    let prefix = "\(account.uuid ?? "")."
                    
                    let i = pendingRequests.partition{$0.identifier.hasPrefix(prefix)}
                    let toRemove = pendingRequests[i...]
                    if !toRemove.isEmpty {
                        notificationCenter.removePendingNotificationRequests(withIdentifiers: toRemove.map{$0.identifier})
                    }
                    pendingRequests.removeLast(pendingRequests.count - i)
                    
                    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(account.characterID).png")
                    try? image.pngData()?.write(to: url)
                    
                    let date = Date()
                    let items = skillQueue.filter{$0.finishDate != nil && $0.finishDate! > date}
                    if let finishDate = items.map({$0.finishDate!}).max() {
                        
                        var requests = notificationOptions.contains(.skillTrainingComplete) ? items.map{self.notificationRequest(item: $0, account: account, characterImageURL: url)} : []
                        
                        let checkpoints: [(SkillQueueNotificationOptions, Date)] = [(.inactive, finishDate),
                                                                                    (.oneHour, finishDate.addingTimeInterval(-3600)),
                                                                                    (.fourHours, finishDate.addingTimeInterval(-3600 * 4)),
                                                                                    (.oneDay, finishDate.addingTimeInterval(-3600 * 24))]
                        requests += checkpoints.filter{notificationOptions.contains($0.0) && $0.1 > date}.map { i -> UNNotificationRequest in
                            let body: String
                            switch i.0 {
                            case .inactive:
                                body = NSLocalizedString("Training Queue is inactive", comment: "")
                            case .oneHour:
                                body = NSLocalizedString("Training Queue will finish in 1 hour.", comment: "")
                            case .fourHours:
                                body = NSLocalizedString("Training Queue will finish in 4 hours.", comment: "")
                            case .oneDay:
                                body = NSLocalizedString("Training Queue will finish in 24 hours.", comment: "")
                            default:
                                body = ""
                            }
                            return self.notificationRequest(identifier: "\(account.uuid ?? "").timeLeft.\(i.0.rawValue)",
                                account: account,
                                subtitle: nil,
                                body: body,
                                date: i.1,
                                characterImageURL: url)
                        }
                        
                        for request in requests {
                            notificationCenter.add(request, withCompletionHandler: nil)
                        }
                    }
                }
            }
        }
    }
    
    func remove(_ accounts: Set<String>, completion: (() -> Void)?) {
        guard !accounts.isEmpty else {
            completion?()
            return
        }
        let notificationCenter = UNUserNotificationCenter.current()
        
        let prefixes = accounts.map{"\($0)."}

        notificationCenter.getPendingNotificationRequests { (pendingRequests) in
            
            for prefix in prefixes {
                let toRemove = pendingRequests.filter{$0.identifier.hasPrefix(prefix)}
                if !toRemove.isEmpty {
                    notificationCenter.removePendingNotificationRequests(withIdentifiers: toRemove.map{$0.identifier})
                }
            }

            completion?()
        }
    }
    
    private func notificationRequest(item: ESI.SkillQueueItem, account: Account, characterImageURL: URL) -> UNNotificationRequest {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(item.skillID)).first()
        let typeName = type?.typeName ?? String(format: NSLocalizedString("Skill %d", comment: ""), Int(item.skillID))
        
        return notificationRequest(identifier: "\(account.uuid ?? "").\(item.skillID).\(item.finishedLevel)",
            account: account,
            subtitle: NSLocalizedString("Skill Training Complete", comment: ""),
            body: "\(typeName): \(item.finishedLevel)",
            date: item.finishDate!,
            characterImageURL: characterImageURL)
    }
    
    private func notificationRequest(identifier: String, account: Account, subtitle: String?, body: String, date: Date, characterImageURL: URL) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = account.characterName ?? String(format: NSLocalizedString("Character %d", comment: ""), Int(account.characterID))
        content.subtitle = subtitle ?? ""
        
        content.body = body
        content.userInfo["account"] = account.uuid
        content.sound = UNNotificationSound.default
        
        
        
        do {
            let attachmentURL = characterImageURL.deletingLastPathComponent().appendingPathComponent("\(identifier).png")
            try FileManager.default.linkItem(at: characterImageURL, to: attachmentURL)
            content.attachments = try [UNNotificationAttachment(identifier: "\(account.characterID)", url: attachmentURL, options: nil)]
        }
        catch {}
        let components = Calendar.current.dateComponents(Set([.year, .month, .day, .hour, .minute, .second, .timeZone]), from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
    
    private func managedObjectContextDidSave(_ note: Notification) {
        guard let context = note.object as? NSManagedObjectContext else {return}
        guard context === managedObjectContext || context.persistentStoreCoordinator === managedObjectContext.persistentStoreCoordinator else {return}

        let toDelete = (note.userInfo?[NSDeletedObjectsKey] as? NSSet)?.compactMap{$0 as? Account}.compactMap{$0.uuid}

        managedObjectContext.perform {
            let toInsert = (note.userInfo?[NSInsertedObjectsKey] as? NSSet)?.compactMap{$0 as? Account}.map{self.managedObjectContext.object(with: $0.objectID) as! Account}
            self.remove(Set(toDelete ?? [])) {
                self.update(Set(toInsert ?? []), completion: nil)
            }
        }
    }
}

//case SkillQueueNotificationOptions.inactive.rawValue:
//    body = NSLocalizedString("Training Queue is inactive", comment: "")
//case SkillQueueNotificationOptions.oneHour.rawValue:
//    body = NSLocalizedString("Training Queue will finish in 1 hour.", comment: "")
//case SkillQueueNotificationOptions.fourHours.rawValue:
//    body = NSLocalizedString("Training Queue will finish in 4 hours.", comment: "")
//case SkillQueueNotificationOptions.oneDay.rawValue:
//    body = NSLocalizedString("Training Queue will finish in 24 hours.", comment: "")


//let content = UNMutableNotificationContent()
//content.title = title
//content.subtitle = NSLocalizedString("Skill Training Complete", comment: "")
//content.body = body
//content.userInfo["accountUUID"] = accountUUID
//
//let attachmentURL = imageURL.deletingLastPathComponent().appendingPathComponent("\(identifier).png")
//try? FileManager.default.linkItem(at: imageURL, to: attachmentURL)
//content.attachments = [try? UNNotificationAttachment(identifier: "uuid", url: attachmentURL, options: nil)].compactMap {$0}
//content.sound = UNNotificationSound.default()
//
//let components = Calendar.current.dateComponents(Set([.year, .month, .day, .hour, .minute, .second, .timeZone]), from: date)
//let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
//let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
//return request
