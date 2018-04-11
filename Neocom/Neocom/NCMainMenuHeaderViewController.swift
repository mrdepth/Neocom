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
		allianceLabel?.superview?.isHidden = true
		
		if let account = NCAccount.current {
			let progressHandler = NCProgressHandler(view: view, totalUnitCount: 6)
			let dataManager = NCDataManager(account: account)
			let characterID = account.characterID
			OperationQueue(qos: .utility).async {
				progressHandler.progress.perform { dataManager.image(characterID: characterID, dimension: 128) }
					.then(on: .main) { result in
						self.characterImageView?.image = result.value
				}

				let character = try progressHandler.progress.perform { dataManager.character() }
					.then(on: .main) { result -> ESI.Character.Information in
						guard let value = result.value else {throw NCDataManagerError.noCacheData}
						self.characterNameLabel?.text = value.name
						return value
					}.catch(on: .main) { error in
						self.characterNameLabel?.text = error.localizedDescription
					}.get()
				
				progressHandler.progress.perform { dataManager.image(corporationID: Int64(character.corporationID), dimension: 32) }
					.then(on: .main) { result in
						self.corporationImageView?.image = result.value
				}

				let corporation = try progressHandler.progress.perform { dataManager.corporation(corporationID: Int64(character.corporationID)) }
					.then(on: .main) { result -> ESI.Corporation.Information in
						guard let corporation = result.value else {throw NCDataManagerError.noCacheData}
						self.corporationLabel?.text = corporation.name
						return corporation
					}.catch(on: .main) { error in
						self.corporationLabel?.text = error.localizedDescription
					}.get()
				

				if let allianceID = corporation.allianceID {
					progressHandler.progress.perform { dataManager.image(allianceID: Int64(allianceID), dimension: 32) }
						.then(on: .main) { result in
							self.allianceImageView?.image = result.value
					}

					progressHandler.progress.perform { dataManager.alliance(allianceID: Int64(allianceID)) }
						.then(on: .main) { result in
							guard let alliance = result.value else {throw NCDataManagerError.noCacheData}
							self.allianceLabel?.text = alliance.name
							self.allianceLabel?.superview?.isHidden = false
						}.catch(on: .main) { error in
							self.allianceLabel?.text = error.localizedDescription
							self.allianceLabel?.superview?.isHidden = true
						}.wait()
				}
				else {
					DispatchQueue.main.async {
						self.allianceLabel?.superview?.isHidden = true
					}
				}
			}.finally {
				progressHandler.finish()
			}
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCAccountsViewController" {
			segue.destination.transitioningDelegate = parent as? UIViewControllerTransitioningDelegate
		}
	}

	@IBAction func onLogout(_ sender: Any) {
		NCAccount.current = nil
	}
	
	@IBAction func onAddAccount(_ sender: Any) {
		ESI.performAuthorization(from: self)

//		let url = OAuth2.authURL(clientID: ESClientID, callbackURL: ESCallbackURL, scope: ESI.Scope.default, state: "esi")
//		if #available(iOS 10.0, *) {
//			UIApplication.shared.open(url, options: [:], completionHandler: nil)
//		} else {
//			UIApplication.shared.openURL(url)
//		}
		
	}
}
