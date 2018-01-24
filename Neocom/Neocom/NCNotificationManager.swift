//
//  NCNotificationManager.swift
//  Neocom
//
//  Created by Artem Shimanski on 31.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import UserNotifications
import EVEAPI
import CoreData

private protocol NotificationRequest {
	var identifier: String {get}
	var accountUUID: String? {get}
	
}

@available(iOS 10.0, *)
extension UNNotificationRequest: NotificationRequest {
	var accountUUID: String? {
		return content.userInfo["accountUUID"] as? String
	}
}

extension UILocalNotification: NotificationRequest {
	var accountUUID: String? {
		return userInfo?["accountUUID"] as? String
	}
	var identifier: String {
		return userInfo?["identifier"] as? String ?? ""
	}
}

class NCNotificationManager: NSObject {
	
	struct SkillQueueNotificationOptions: OptionSet {
		var rawValue: Int
		static let inactive = SkillQueueNotificationOptions(rawValue: 1 << 0)
		static let oneHour = SkillQueueNotificationOptions(rawValue: 1 << 1)
		static let fourHours = SkillQueueNotificationOptions(rawValue: 1 << 2)
		static let oneDay = SkillQueueNotificationOptions(rawValue: 1 << 3)
		static let skillTrainingComplete = SkillQueueNotificationOptions(rawValue: 1 << 4)
		
		static let `default`: SkillQueueNotificationOptions = [.inactive, .oneHour, .fourHours, .oneDay, .skillTrainingComplete]
	}
	
	lazy var skillQueueNotificationOptions: SkillQueueNotificationOptions = {
		if let setting = (NCSetting.setting(key: NCSetting.Key.skillQueueNotifications)?.value as? NSNumber)?.intValue {
			return SkillQueueNotificationOptions(rawValue: setting)
		}
		else {
			return .default
		}
	}()
	
	static let sharedManager = NCNotificationManager()
	
	override private init() {
		super.init()
		NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	private var lastScheduleDate: Date?
	
	func setNeedsUpdate() {
		lastScheduleDate = nil
	}
	
	func schedule(completionHandler: ((Bool) -> Void)? = nil) {
		guard let storage = NCStorage.sharedStorage else {
			completionHandler?(false)
			return
		}
		
		guard (lastScheduleDate ?? Date.distantPast).timeIntervalSinceNow < -600 else {
			completionHandler?(false)
			return
		}
		
		pendingNotificationRequests { requests in
			let dispatchGroup = DispatchGroup()
			
			dispatchGroup.enter()
			var pending = requests
			var queue: [(Int64, String, [ESI.Skills.SkillQueueItem], Date, String)] = []
			
			storage.performBackgroundTask { managedObjectContext in
				defer {dispatchGroup.leave()}
				guard let accounts: [NCAccount] = managedObjectContext.fetch("Account") else {
					return
				}

				accounts.forEach { account in
					let uuid = account.uuid
					let i = pending.partition {$0.accountUUID == uuid}
					let requests = Array(pending[0..<i])
					pending.removeSubrange(0..<i)
					
					let dataManager = NCDataManager(account: account)
					let characterID = account.characterID
					let characterName = account.characterName ?? ""

					let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(characterID)_64.png")
					
					dispatchGroup.enter()
					
					let lifeTime = NCExtendedLifeTime(managedObjectContext)
					
					dataManager.skillQueue { result in
						switch result {
						case let .success(value, _):
							if let uuid = uuid {
								queue.append((characterID, characterName, value, value.flatMap{$0.finishDate}.max() ?? Date.distantFuture, uuid))
							}
							dispatchGroup.enter()
							dataManager.image(characterID: characterID, dimension: 64) { result in
								if let image = result.value {
									try? UIImagePNGRepresentation(image)?.write(to: url)
								}
								self.schedule(skillQueue: value, account: account, requests: requests, imageURL: url) { result in
									dispatchGroup.leave()
									lifeTime.finalize()
								}
							}
						case .failure:
							lifeTime.finalize()
						}
						dispatchGroup.leave()
					}
				}
				
				self.remove(requests: pending)
			}
			
			dispatchGroup.notify(queue: .main) { [weak self] in
				NCDatabase.sharedDatabase?.performBackgroundTask { (context) in
					if let url = WidgetData.url {
						let date = Date()
						let invTypes = NCDBInvType.invTypes(managedObjectContext: context)
						let accounts = Array(queue.filter{!$0.2.isEmpty}.sorted{$0.3 < $1.3}.prefix(4))
							.map { i -> WidgetData.Account in
								let skills = i.2.flatMap { j-> WidgetData.Account.SkillQueueItem? in
									guard let type = invTypes[j.skillID],
										let skill = NCSkill(type: type, skill: j),
										let startDate = j.startDate,
										let finishDate = j.finishDate,
										let skillName = type.typeName,
										finishDate > date else {return nil}
									
									return WidgetData.Account.SkillQueueItem(skillName: skillName, startDate: startDate, finishDate: finishDate, level: j.finishedLevel - 1, rank: skill.rank, startSP: j.levelStartSP, endSP: j.levelEndSP)
								}
								return WidgetData.Account(characterID: i.0, characterName: i.1, uuid: i.4, skillQueue: skills)
						}
						
						let dispatchGroup = DispatchGroup()

						let widgetData = WidgetData(accounts: accounts)
						
						let fileManager = FileManager.default
						let baseURL = url.deletingLastPathComponent()
						try? fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil, options: []).forEach {
							if $0.pathExtension == "png" {
								try? fileManager.removeItem(at: $0)
							}
						}
						try? fileManager.removeItem(at: url)
						
						do {
							let data = try JSONEncoder().encode(widgetData)
							try data.write(to: url)
							let dataManager = NCDataManager()
							
							accounts.forEach { account in
								dispatchGroup.enter()
								dataManager.image(characterID: account.characterID, dimension: 64) { result in
									if let image = result.value, let data = UIImagePNGRepresentation(image) {
										try? data.write(to: baseURL.appendingPathComponent("\(account.characterID).png"))
									}
									dispatchGroup.leave()
								}
							}
						}
						catch {
							
						}
						dispatchGroup.notify(queue: .main) {
							self?.lastScheduleDate = Date()
							completionHandler?(true)
						}
					}
				}
			}
		}
	}
	
	private func pendingNotificationRequests(completionHandler: @escaping ([NotificationRequest]) -> Void) {
		if #available(iOS 10.0, *) {
			UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
				completionHandler(requests)
			}
		} else {
			completionHandler(UIApplication.shared.scheduledLocalNotifications ?? [])
		}
	}
	
	private func remove(requests: [NotificationRequest]) {
		if #available(iOS 10.0, *) {
			let ids = requests.map{$0.identifier}
			UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
		} else {
			let application = UIApplication.shared
			requests.flatMap {$0 as? UILocalNotification}.forEach {
				application.cancelLocalNotification($0)
			}
		}
	}

	
	private func removeAllNotifications() {
		if #available(iOS 10.0, *) {
			UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
		} else {
			// Fallback on earlier versions
		}
	}
	
	private func schedule(skillQueue: [ESI.Skills.SkillQueueItem], account: NCAccount, requests: [NotificationRequest], imageURL: URL, completionHandler: ((Bool) -> Void)?) {
		let options = self.skillQueueNotificationOptions
		guard let context = account.managedObjectContext, !options.isEmpty else {
			completionHandler?(false)
			return
		}
		
		
		context.perform {
			guard let uuid = account.uuid else {
				completionHandler?(false)
				return
			}
			let characterName = account.characterName ?? ""
			
			let date = Date()
			let value = skillQueue.filter {$0.finishDate != nil && $0.finishDate! > date}.sorted {$0.finishDate! < $1.finishDate!}
			self.remove(requests: requests)
			
			
			
			let dispatchGroup = DispatchGroup()
			
			if options.contains(.skillTrainingComplete) {
				NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext -> [NotificationRequest] in
					let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
					return value.map { skill -> NotificationRequest in
						return self.request(title: characterName,
						                    subtitle: NSLocalizedString("Skill Training Complete", comment: ""),
						                    body: "\(invTypes[skill.skillID]?.typeName ?? NSLocalizedString("Unknown", comment: "")): \(skill.finishedLevel)",
							date: skill.finishDate!,
							imageURL: imageURL,
							identifier: "\(uuid).\(skill.skillID).\(skill.finishedLevel)",
							accountUUID: uuid)
					}
					}.forEach {
						dispatchGroup.enter()
						self.add(request: $0) { error in
							dispatchGroup.leave()
						}
				}
			}
			
			
			if let lastSkill = value.last {
				let a: [(SkillQueueNotificationOptions, Date)] = [(.inactive, lastSkill.finishDate!),
				                                                  (.oneHour, lastSkill.finishDate!.addingTimeInterval(-3600)),
				                                                  (.fourHours, lastSkill.finishDate!.addingTimeInterval(-3600 * 4)),
				                                                  (.oneDay, lastSkill.finishDate!.addingTimeInterval(-3600 * 24))]
				a.filter{options.contains($0.0) && $0.1 > date}.flatMap { (option, date) -> NotificationRequest? in
					let body: String
					switch option.rawValue {
					case SkillQueueNotificationOptions.inactive.rawValue:
						body = NSLocalizedString("Training Queue is inactive", comment: "")
					case SkillQueueNotificationOptions.oneHour.rawValue:
						body = NSLocalizedString("Training Queue will finish in 1 hour.", comment: "")
					case SkillQueueNotificationOptions.fourHours.rawValue:
						body = NSLocalizedString("Training Queue will finish in 4 hours.", comment: "")
					case SkillQueueNotificationOptions.oneDay.rawValue:
						body = NSLocalizedString("Training Queue will finish in 24 hours.", comment: "")
					default:
						return nil
					}

					return self.request(title: characterName,
					               subtitle: nil,
					               body: body,
					               date: date,
					               imageURL: imageURL,
					               identifier: "\(uuid).\(option.rawValue)",
						accountUUID: uuid)

					}.forEach {
						dispatchGroup.enter()
						self.add(request: $0) { error in
							dispatchGroup.leave()
						}
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				completionHandler?(true)
			}
			
		}
	}
	
	private func request (title: String, subtitle: String?, body: String, date: Date, imageURL: URL, identifier: String, accountUUID: String) -> NotificationRequest {
		if #available(iOS 10.0, *) {
			let content = UNMutableNotificationContent()
			content.title = title
			content.subtitle = NSLocalizedString("Skill Training Complete", comment: "")
			content.body = body
			content.userInfo["accountUUID"] = accountUUID
			
			let attachmentURL = imageURL.deletingLastPathComponent().appendingPathComponent("\(identifier).png")
			try? FileManager.default.linkItem(at: imageURL, to: attachmentURL)
			content.attachments = [try? UNNotificationAttachment(identifier: "uuid", url: attachmentURL, options: nil)].flatMap {$0}
			content.sound = UNNotificationSound.default()
			
			let components = Calendar.current.dateComponents(Set([.year, .month, .day, .hour, .minute, .second, .timeZone]), from: date)
			let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
			let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
			return request
		} else {
			let notification = UILocalNotification()
			notification.alertTitle = title
			if let subtitle = subtitle {
				notification.alertBody = "\(subtitle)\n\(body)"
			}
			else {
				notification.alertBody = body
			}
			notification.fireDate = date
			notification.userInfo = ["accountUUID": accountUUID]
			return notification
		}
	}
	
	private func add(request: NotificationRequest, completionHandler: ((Error?) -> Void)? = nil) {
		if #available(iOS 10.0, *) {
			UNUserNotificationCenter.current().add(request as! UNNotificationRequest, withCompletionHandler: completionHandler)
		}
		else {
			UIApplication.shared.scheduleLocalNotification(request as! UILocalNotification)
			completionHandler?(nil)
		}
	}

	@objc private func managedObjectContextDidSave(_ note: Notification) {
		guard let viewContext = NCStorage.sharedStorage?.viewContext, let context = note.object as? NSManagedObjectContext else {return}
		guard context.persistentStoreCoordinator === viewContext.persistentStoreCoordinator else {return}
		
		if (note.userInfo?[NSDeletedObjectsKey] as? NSSet)?.contains(where: {$0 is NCAccount}) == true ||
			(note.userInfo?[NSInsertedObjectsKey] as? NSSet)?.contains(where: {$0 is NCAccount}) == true {
			lastScheduleDate = nil
		}
	}
}
