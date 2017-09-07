//
//  NCSettingsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 07.09.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCSkillQueueNotificationOptionsSection: DefaultTreeSection {
	let setting: NCSetting
	
	init(setting: NCSetting) {
		self.setting = setting
		
		var options: NCNotificationManager.SkillQueueNotificationOptions =  {
			guard let rawValue = (setting.value as? NSNumber)?.intValue else {return nil}
			return NCNotificationManager.SkillQueueNotificationOptions(rawValue: rawValue)
		}() ?? .default
		
		let keys: [NCNotificationManager.SkillQueueNotificationOptions] = [.inactive,
		                                                                    .oneHour,
		                                                                    .fourHours,
		                                                                    .oneDay,
		                                                                    .skillTrainingComplete]
		
		let children = keys.flatMap { key -> NCSwitchRow? in
			let title: String
			
			switch key.rawValue {
			case NCNotificationManager.SkillQueueNotificationOptions.inactive.rawValue:
				title = NSLocalizedString("Inactive Skill Queue", comment: "")
			case NCNotificationManager.SkillQueueNotificationOptions.oneHour.rawValue:
				title = NSLocalizedString("1 Hour Left", comment: "")
			case NCNotificationManager.SkillQueueNotificationOptions.fourHours.rawValue:
				title = NSLocalizedString("4 Hours Left", comment: "")
			case NCNotificationManager.SkillQueueNotificationOptions.oneDay.rawValue:
				title = NSLocalizedString("24 Hours Left", comment: "")
			case NCNotificationManager.SkillQueueNotificationOptions.skillTrainingComplete.rawValue:
				title = NSLocalizedString("Skill Training Complete", comment: "")
			default:
				return nil
			}

			return NCSwitchRow(title: title, value: options.contains(key), handler: { value in
				if value {
					options.insert(key)
				}
				else {
					options.remove(key)
				}
				setting.value = options.rawValue as NSNumber
				NCNotificationManager.sharedManager.setNeedsUpdate()
			})
		}
		
		super.init(nodeIdentifier: "NotificationOptions", image: nil, title: NSLocalizedString("Skill Queue Notifications", comment: "").uppercased(), children: children)
	}
}

class NCSettingsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCSwitchTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default])
		
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		guard let context = NCStorage.sharedStorage?.viewContext else {return}
		if context.hasChanges {
			try? context.save()
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		var sections = [TreeNode]()
		
		if let setting = NCSetting.setting(key: NCSetting.Key.skillQueueNotifications) {
			sections.append(NCSkillQueueNotificationOptionsSection(setting: setting))
		}

		treeController?.content = RootNode(sections, collapseIdentifier: "NCFeedsViewController")
		completionHandler()
	}
}
