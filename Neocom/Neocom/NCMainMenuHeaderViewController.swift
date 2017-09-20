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
			let dispatchGroup = DispatchGroup()
			
			
			dispatchGroup.enter()
			progressHandler.progress.becomeCurrent(withPendingUnitCount: 1)
			dataManager.character { result in
				switch result {
					
				case let .success(value, _):
					self.characterNameLabel?.text = value.name
					let corporationID = value.corporationID
					
					dispatchGroup.enter()
					progressHandler.progress.becomeCurrent(withPendingUnitCount: 1)
					dataManager.corporation(corporationID: Int64(corporationID)) { result in
						switch result {
						case let .success(value, _):
							self.corporationLabel?.text = value.corporationName
							if let allianceID = value.allianceID {
								self.allianceLabel?.superview?.isHidden = false
								dispatchGroup.enter()
								progressHandler.progress.becomeCurrent(withPendingUnitCount: 1)
								dataManager.alliance(allianceID: Int64(allianceID)) { result in
									switch result {
									case let .success(value, _):
										self.allianceLabel?.text = value.allianceName
										
										dispatchGroup.enter()
										progressHandler.progress.becomeCurrent(withPendingUnitCount: 1)
										dataManager.image(allianceID: Int64(allianceID), dimension: 32) { result in
											switch result {
											case let .success(value, _):
												self.allianceImageView?.image = value
											default:
												break
											}
											dispatchGroup.leave()
										}
										progressHandler.progress.resignCurrent()
									case let .failure(error):
										self.allianceLabel?.text = error.localizedDescription
									}
									
									dispatchGroup.leave()
								}
								progressHandler.progress.resignCurrent()
							}
							else {
								self.allianceLabel?.superview?.isHidden = true
							}
							
							dispatchGroup.enter()
							progressHandler.progress.becomeCurrent(withPendingUnitCount: 1)
							dataManager.image(corporationID: Int64(corporationID), dimension: 32) { result in
								switch result {
								case let .success(value, _):
									self.corporationImageView?.image = value
								default:
									break
								}
								dispatchGroup.leave()
							}
							progressHandler.progress.resignCurrent()
						case let .failure(error):
							self.corporationLabel?.text = error.localizedDescription
						}

						dispatchGroup.leave()
					}
					progressHandler.progress.resignCurrent()
					
					dispatchGroup.enter()
					progressHandler.progress.becomeCurrent(withPendingUnitCount: 1)
					dataManager.image(characterID: account.characterID, dimension: 128) { result in
						switch result {
						case let .success(value, _):
							self.characterImageView?.image = value
						default:
							break
						}
						dispatchGroup.leave()
					}
					progressHandler.progress.resignCurrent()
					
				case let .failure(error):
					self.characterNameLabel?.text = error.localizedDescription
					
				}
				
				dispatchGroup.leave()
			}
			progressHandler.progress.resignCurrent()
			
			dispatchGroup.notify(queue: .main) {
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
