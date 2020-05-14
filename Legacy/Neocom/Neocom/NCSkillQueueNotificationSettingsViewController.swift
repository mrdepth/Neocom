//
//  NCSkillQueueNotificationSettingsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import EVEAPI
import Futures

class NCSettingsAccountSwitchTableViewCell: NCAccountTableViewCell {
	@IBOutlet weak var switchControl: UISwitch!
	
	var actionHandler: NCActionHandler<UISwitch>?
	
	override func prepareForReuse() {
		super.prepareForReuse()
		actionHandler = nil
	}
}

extension Prototype {
	enum NCSettingsAccountSwitchTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCSettingsAccountSwitchTableViewCell")
	}
}

class NCNotificationSettingsAccountsNode: NCAccountsNode<NCSettingsAccountSwitchRow> {
	let setting: NCSetting
	lazy var accounts = setting.value as? Set<String> ?? Set()
	let handler: () -> Void
	
	var isFull: Bool {
		return accounts.count >= 10
	}
	
	init(context: NSManagedObjectContext, setting: NCSetting, handler: @escaping () -> Void) {
		self.setting = setting
		self.handler = handler
		super.init(context: context, cachePolicy: .useProtocolCachePolicy)
	}
}


class NCSettingsAccountSwitchRow: NCAccountRow {
	
	required init(object: NCAccount) {
		super.init(object: object)
		canMove = false
		cellIdentifier = Prototype.NCSettingsAccountSwitchTableViewCell.default.reuseIdentifier
	}

	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCSettingsAccountSwitchTableViewCell else {return}
		guard let uuid = object.uuid else {return}
		guard let root = (sequence(first: parent, next: {$0?.parent}).first(where: {$0 is NCNotificationSettingsAccountsNode}) as? NCNotificationSettingsAccountsNode) else {return}
		
		let isOn = root.accounts.contains(uuid)
		cell.switchControl.isOn = isOn
		cell.switchControl.isEnabled = isOn || !root.isFull
		
		cell.actionHandler = NCActionHandler(cell.switchControl, for: .valueChanged) { [weak root] control in
			guard let root = root else {return}
			if control.isOn {
				root.accounts.insert(uuid)
			}
			else {
				root.accounts.remove(uuid)
			}
			root.handler()
		}
	}
}


class NCSkillQueueNotificationEventsSection: DefaultTreeSection {
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
		
		let children = keys.compactMap { key -> NCSwitchRow? in
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
		
		super.init(nodeIdentifier: "NotificationOptions", image: nil, title: NSLocalizedString("Events", comment: "").uppercased(), children: children)
	}
}



class NCSkillQueueNotificationSettingsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
							Prototype.NCSwitchTableViewCell.default,
							Prototype.NCDefaultTableViewCell.default,
							Prototype.NCActionTableViewCell.default])
		
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		guard let context = NCStorage.sharedStorage?.viewContext else {return}
		if context.hasChanges {
			try? context.save()
		}
	}
	
	override func content() -> Future<TreeNode?> {
		var sections = [TreeNode]()
		
		if let setting = NCSetting.setting(key: NCSetting.Key.skillQueueNotifications) {
			sections.append(NCSkillQueueNotificationOptionsSection(setting: setting))
		}
		
		let clearCache = Router.Custom { (controller, _) in
			let alert = UIAlertController(title: NSLocalizedString("Are You Sure?", comment: ""), message: NSLocalizedString("Some features may be temporarily unavailable", comment: ""), preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: NSLocalizedString("Clear", comment: ""), style: .default, handler: { (_) in
				NCCache.sharedCache?.performBackgroundTask { (managedObjectContext) in
					guard let records: [NCCacheRecord] = managedObjectContext.fetch("Record") else {return}
					records.forEach { managedObjectContext.delete($0) }
				}
			}))
			alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
			controller.present(alert, animated: true, completion: nil)
		}
		
		guard let context = NCStorage.sharedStorage?.viewContext else {return .init(nil)}
		guard let setting = NCSetting.setting(key: NCSetting.Key.skillQueueNotificationsAccounts) else {return .init(nil)}
		
		sections.append(NCNotificationSettingsAccountsNode(context: context, setting: setting, handler: {
			
		}))
		return .init(RootNode(sections, collapseIdentifier: "NCFeedsViewController"))
	}
}
