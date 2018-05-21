//
//  NCZKillboardSummaryViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCZKillboardSummaryViewController: NCPageViewController {
	
	var contact: NCContact?
	
	var killsViewController: NCZKillboardKillmailsViewController?
	var lossesViewController: NCZKillboardKillmailsViewController?
	
	private var corporation: NCContact?
	private var alliance: NCContact?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		killsViewController = storyboard!.instantiateViewController(withIdentifier: "NCZKillboardKillmailsViewController") as? NCZKillboardKillmailsViewController
		killsViewController?.title = NSLocalizedString("Kills", comment: "")
		lossesViewController = storyboard!.instantiateViewController(withIdentifier: "NCZKillboardKillmailsViewController") as? NCZKillboardKillmailsViewController
		lossesViewController?.title = NSLocalizedString("Losses", comment: "")
		

		let filter: [ZKillboard.Filter]?

		if let contact = contact {
			title = contact.name

			let dataManager = NCDataManager(account: NCAccount.current)
			
			let dispatchGroup = DispatchGroup()
			var contacts: [Int64: NSManagedObjectID]?
			
			switch contact.recipientType! {
			case .character:
				filter = [.characterID([contact.contactID])]
				
				dispatchGroup.enter()
				dataManager.character(characterID: contact.contactID).then(on: .main) { result in
					defer {dispatchGroup.leave()}
					guard let value = result.value else {return}
					
					var ids = Set([Int64(value.corporationID)])
					if let allianceID = value.allianceID {
						ids.insert(Int64(allianceID))
					}
					
					if !ids.isEmpty {
						dispatchGroup.enter()
						dataManager.contacts(ids: ids).then(on: .main) { result in
							contacts = result
							dispatchGroup.leave()
						}
					}
				}
			case .corporation:
				filter = [.corporationID([contact.contactID])]
				
				dispatchGroup.enter()
				dataManager.corporation(corporationID: contact.contactID).then(on: .main) { result in
					defer {dispatchGroup.leave()}
					guard let value = result.value else {return}
					
					var ids = Set<Int64>()
					if let allianceID = value.allianceID {
						ids.insert(Int64(allianceID))
					}
					
					if !ids.isEmpty {
						dispatchGroup.enter()
						dataManager.contacts(ids: ids).then(on: .main) { result in
							contacts = result
							dispatchGroup.leave()
						}
					}
				}
				
			case .alliance:
				filter = [.allianceID([contact.contactID])]
			default:
				filter = nil
			}
			
			navigationItem.rightBarButtonItem?.isEnabled = false
			dispatchGroup.notify(queue: .main) {
				let context = NCCache.sharedCache?.viewContext
				let c = Dictionary(uniqueKeysWithValues: contacts?.values.compactMap { (try? context?.existingObject(with: $0)) as? NCContact }.map { ($0.contactID, $0) } ?? [])
				self.corporation = c.values.first {$0.recipientType == .corporation}
				self.alliance = c.values.first {$0.recipientType == .alliance}
				self.navigationItem.rightBarButtonItem?.isEnabled = contacts?.isEmpty == false
			}
		}
		else {
			filter = nil
		}
		

		
		if let filter = filter {
			var kills = filter
			kills.append(.kills)
			var losses = filter
			losses.append(.losses)
			killsViewController!.filter = kills
			lossesViewController!.filter = losses
		}
		
		viewControllers = [killsViewController!, lossesViewController!]
		
	}
	
	@IBAction func onActions(_ sender: UIBarButtonItem) {
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		if let corporation = corporation {
			controller.addAction(UIAlertAction(title: corporation.name, style: .default) { [weak self] _ in
				guard let strongSelf = self else {return}
				Router.KillReports.ContactReports(contact: corporation.objectID).perform(source: strongSelf, sender: sender)
			})
		}
		if let alliance = alliance {
			controller.addAction(UIAlertAction(title: alliance.name, style: .default) { [weak self] _ in
				guard let strongSelf = self else {return}
				Router.KillReports.ContactReports(contact: alliance.objectID).perform(source: strongSelf, sender: sender)
			})
		}
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		present(controller, animated: true, completion: nil)
		controller.popoverPresentationController?.barButtonItem = sender
	}
}
