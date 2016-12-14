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
					
				case let .success(value: value, cacheRecordID: _):
					self.characterNameLabel?.text = value.name
					let corporationID = value.corporationID
					
					dispatchGroup.enter()
					progressHandler.progress.becomeCurrent(withPendingUnitCount: 1)
					dataManager.corporation(corporationID: corporationID) { result in
						switch result {
						case let .success(value: value, cacheRecordID: _):
							self.corporationLabel?.text = value.corporationName
							let allianceID = value.allianceID
							if allianceID > 0 {
								self.allianceLabel?.superview?.isHidden = false
								dispatchGroup.enter()
								progressHandler.progress.becomeCurrent(withPendingUnitCount: 1)
								dataManager.alliance(allianceID: allianceID) { result in
									switch result {
									case let .success(value: value, cacheRecordID: _):
										self.allianceLabel?.text = value.allianceName
										
										dispatchGroup.enter()
										progressHandler.progress.becomeCurrent(withPendingUnitCount: 1)
										dataManager.image(allianceID: allianceID, dimension: 32) { result in
											switch result {
											case let .success(value: value, cacheRecordID: _):
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
							dataManager.image(corporationID: corporationID, dimension: 32) { result in
								switch result {
								case let .success(value: value, cacheRecordID: _):
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
						case let .success(value: value, cacheRecordID: _):
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
				progressHandler.finih()
			}
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCAccountsViewController", let delegate = self.parent as? UIViewControllerTransitioningDelegate {
			segue.destination.transitioningDelegate = delegate
		}
	}

	@IBAction func onLogout(_ sender: Any) {
		NCAccount.current = nil
	}
	
	@IBAction func onAddAccount(_ sender: Any) {
		UIApplication.shared.openURL(ESAPI.oauth2url(clientID: ESClientID, callbackURL: ESCallbackURL, scope: ESScope.all))
	}
}
