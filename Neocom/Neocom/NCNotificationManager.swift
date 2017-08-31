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

protocol NotificationRequest: class {
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
	}
	
	lazy var skillQueueNotificationOptions: [SkillQueueNotificationOptions] = {
		if let setting = (NCSetting.setting(key: "NCNotificationManager.skillQueue")?.value as? NSNumber)?.intValue {
			return [SkillQueueNotificationOptions(rawValue: setting)]
		}
		else {
			return [.inactive, .oneHour, .fourHours, .oneDay]
		}
	}()
	
	static let sharedManager = NCNotificationManager()
	
	override private init() {
		super.init()
	}
	
	func schedule(completionHandler: ((Bool) -> Void)? = nil) {
		guard let storage = NCStorage.sharedStorage else {
			completionHandler?(false)
			return
		}
		
		pendingNotificationRequests { requests in
			let dispatchGroup = DispatchGroup()
			
			dispatchGroup.enter()
			var pending = requests
			storage.performBackgroundTask { managedObjectContext in
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

					let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(characterID)_64.png")
					
					dispatchGroup.enter()
					
					let lifeTime = NCExtendedLifeTime(managedObjectContext)
					
					dataManager.skillQueue { result in
						switch result {
						case let .success(value, _):
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
							dispatchGroup.leave()
							lifeTime.finalize()
						}
					}
				}
				
				self.remove(requests: pending)
				dispatchGroup.leave()
			}
			
			dispatchGroup.notify(queue: .main) {
				completionHandler?(true)
			}
		}
		
		
		completionHandler?(false)
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
		guard let context = account.managedObjectContext else {
			completionHandler?(false)
			return
		}
		let options = self.skillQueueNotificationOptions
		
		context.perform {
			guard let uuid = account.uuid else {
				completionHandler?(false)
				return
			}
			let characterName = account.characterName ?? ""
			
			let date = Date()
			let value = skillQueue.filter {$0.finishDate != nil && $0.finishDate! > date}.sorted {$0.finishDate! < $1.finishDate!}
			self.remove(requests: requests)
			
			
			if #available(iOS 10.0, *) {
				let dispatchGroup = DispatchGroup()
				
				let calendar = Calendar.current
				let notificationCenter = UNUserNotificationCenter.current()
				
				NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext -> [UNNotificationRequest] in
					let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
					return value.map { skill -> UNNotificationRequest in
						let identifier = "\(uuid).\(skill.skillID).\(skill.finishedLevel)"
						
						let content = UNMutableNotificationContent()
						content.title = characterName
						content.subtitle = NSLocalizedString("Skill Training Complete", comment: "")
						content.body = "\(invTypes[skill.skillID]?.typeName ?? NSLocalizedString("Unknown", comment: "")): \(skill.finishedLevel)"
						content.userInfo["accountUUID"] = uuid
						
						let attachmentURL = imageURL.deletingLastPathComponent().appendingPathComponent("\(identifier).png")
						try? FileManager.default.linkItem(at: imageURL, to: attachmentURL)
						content.attachments = [try? UNNotificationAttachment(identifier: "uuid", url: attachmentURL, options: nil)].flatMap {$0}
						content.sound = UNNotificationSound.default()
						
						let finishDate = skill.finishDate!
						//							let finishDate = Date(timeIntervalSinceNow: 5)
						let components = calendar.dateComponents(Set([.year, .month, .day, .hour, .minute, .second, .timeZone]), from: finishDate)
						let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
						let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
						return request
					}
					
					
					}.forEach {
						dispatchGroup.enter()
						notificationCenter.add($0) { error in
							dispatchGroup.leave()
						}
				}
				
				if let lastSkill = value.last {
					let a: [(SkillQueueNotificationOptions, Date)] = [(.inactive, lastSkill.finishDate!),
					                                                  (.oneHour, lastSkill.finishDate!.addingTimeInterval(-3600)),
					                                                  (.fourHours, lastSkill.finishDate!.addingTimeInterval(-3600 * 4)),
					                                                  (.oneDay, lastSkill.finishDate!.addingTimeInterval(-3600 * 24))]
					a.filter{options.contains($0.0) && $0.1 > date}.map { (option, date) -> UNNotificationRequest in
						let identifier = "\(uuid).\(option.rawValue)"
						
						let content = UNMutableNotificationContent()
						content.title = characterName
						content.userInfo["accountUUID"] = uuid
						
						switch option.rawValue {
						case SkillQueueNotificationOptions.inactive.rawValue:
							content.body = NSLocalizedString("Training Queue is inactive", comment: "")
						case SkillQueueNotificationOptions.oneHour.rawValue:
							content.body = NSLocalizedString("Training Queue will finish in 1 hour.", comment: "")
						case SkillQueueNotificationOptions.fourHours.rawValue:
							content.body = NSLocalizedString("Training Queue will finish in 4 hours.", comment: "")
						case SkillQueueNotificationOptions.oneDay.rawValue:
							content.body = NSLocalizedString("Training Queue will finish in 24 hours.", comment: "")
						default:
							break
						}

						let attachmentURL = imageURL.deletingLastPathComponent().appendingPathComponent("\(identifier).png")
						try? FileManager.default.linkItem(at: imageURL, to: attachmentURL)
						content.attachments = [try? UNNotificationAttachment(identifier: "uuid", url: attachmentURL, options: nil)].flatMap {$0}
						content.sound = UNNotificationSound.default()

						let components = calendar.dateComponents(Set([.year, .month, .day, .hour, .minute, .second, .timeZone]), from: date)
						let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
						let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
						return request
						}.forEach {
							dispatchGroup.enter()
							notificationCenter.add($0) { error in
								dispatchGroup.leave()
							}
					}
				}
				
				dispatchGroup.notify(queue: .main) {
					completionHandler?(true)
				}
				
			} else {
				completionHandler?(true)
			}
		}
	}
}
