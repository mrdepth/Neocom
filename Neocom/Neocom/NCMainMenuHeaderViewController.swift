//
//  NCMainMenuHeaderViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCMainMenuHeaderViewController: UIViewController {
	@IBOutlet weak var characterNameLabel: UILabel?
	@IBOutlet weak var characterImageView: UIImageView?
	@IBOutlet weak var corporationLabel: UILabel?
	@IBOutlet weak var allianceLabel: UILabel?
	@IBOutlet weak var corporationImageView: UIImageView?
	@IBOutlet weak var allianceImageView: UIImageView?
	@IBOutlet weak var heightConstraint: NSLayoutConstraint?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		characterNameLabel?.text = " "
		corporationLabel?.text = " "
		allianceLabel?.text = " "
		characterImageView?.image = nil
		corporationImageView?.image = nil
		allianceImageView?.image = nil
		
		/*if let account = NCAccount.currentAccount, let character = account.character {
			let dataManager = NCDataManager()
			if account.eveAPIKey.corporate {
				if let corporationImageView = corporationImageView, character.corporationID > 0 {
					dataManager.image(corporationID: character.corporationID, preferredSize: CGSize(width: 128, height:128), cachePolicy: .useProtocolCachePolicy, completionHandler: { (image, _, _) in
						corporationImageView.image = image
					})
				}
				if let allianceImageView = allianceImageView, character.allianceID > 0 {
					dataManager.image(allianceID: character.allianceID, preferredSize: CGSize(width: 32, height:32), cachePolicy: .useProtocolCachePolicy, completionHandler: { (image, _, _) in
						allianceImageView.image = image
					})
				}
				else {
					heightConstraint?.priority = 999
				}
			}
			else {
				if let characterImageView = characterImageView {
					dataManager.image(characterID: character.characterID, preferredSize: CGSize(width: 128, height:128), cachePolicy: .useProtocolCachePolicy, completionHandler: { (image, _, _) in
						characterImageView.image = image
					})
				}

				if let corporationImageView = corporationImageView, character.corporationID > 0 {
					dataManager.image(corporationID: character.corporationID, preferredSize: CGSize(width: 32, height:32), cachePolicy: .useProtocolCachePolicy, completionHandler: { (image, _, _) in
						corporationImageView.image = image
					})
				}
				if let allianceImageView = allianceImageView, character.allianceID > 0 {
					dataManager.image(allianceID: character.allianceID, preferredSize: CGSize(width: 32, height:32), cachePolicy: .useProtocolCachePolicy, completionHandler: { (image, _, _) in
						allianceImageView.image = image
					})
				}
			}
		}*/
	}

	@IBAction func onLogout(_ sender: Any) {
		NCAccount.currentAccount = nil
	}
	
	@IBAction func onAddAccount(_ sender: Any) {
		UIApplication.shared.openURL(ESAPI.oauth2url(clientID: ESClientID, callbackURL: ESCallbackURL, scope: ESScope.all))
	}
}
