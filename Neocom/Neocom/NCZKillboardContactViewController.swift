//
//  NCZKillboardContactViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCZKillboardContactViewController: NCPageViewController {
	
	var contact: NCContact?
	
	var killsViewController: NCZKillboardKillmailsViewController?
	var lossesViewController: NCZKillboardKillmailsViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = contact?.name
		
		killsViewController = storyboard!.instantiateViewController(withIdentifier: "NCZKillboardKillmailsViewController") as? NCZKillboardKillmailsViewController
		killsViewController?.title = NSLocalizedString("Kills", comment: "")
		lossesViewController = storyboard!.instantiateViewController(withIdentifier: "NCZKillboardKillmailsViewController") as? NCZKillboardKillmailsViewController
		lossesViewController?.title = NSLocalizedString("Losses", comment: "")
		
		guard let contact = contact else {return}
		
		let filter: [ZKillboard.Filter]?
		
		switch contact.recipientType! {
		case .character:
			filter = [.characterID([contact.contactID])]
		case .corporation:
			filter = [.corporationID([contact.contactID])]
		case .alliance:
			filter = [.allianceID([contact.contactID])]
		default:
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
	
}
