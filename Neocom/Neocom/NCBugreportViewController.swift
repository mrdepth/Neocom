//
//  NCBugreportViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class NCBugreportViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.compact,
							Prototype.NCHeaderTableViewCell.static])
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		let rows = [
			
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.compact,
						   nodeIdentifier: "CharacterSheet",
						   image: #imageLiteral(resourceName: "charactersheet"),
						   title: NSLocalizedString("Character Sheet", comment: ""),
						   accessoryType: .disclosureIndicator,
						   route: Router.Custom { [weak self] _,_ in self?.reportCharacterSheet()}),
			
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.compact,
						   nodeIdentifier: "Skills",
						   image: #imageLiteral(resourceName: "skills"),
						   title: NSLocalizedString("Skills", comment: ""),
						   accessoryType: .disclosureIndicator,
						   route: Router.Custom { [weak self] _,_ in self?.reportSkills()}),
			
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.compact,
						   nodeIdentifier: "Assets",
						   image: #imageLiteral(resourceName: "assets"),
						   title: NSLocalizedString("Assets", comment: ""),
						   accessoryType: .disclosureIndicator,
						   route: Router.Custom { [weak self] _,_ in self?.reportAssets()}),
			
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.compact,
						   nodeIdentifier: "MarketOrders",
						   image: #imageLiteral(resourceName: "marketdeliveries"),
						   title: NSLocalizedString("Market Orders", comment: ""),
						   accessoryType: .disclosureIndicator,
						   route: Router.Custom { [weak self] _,_ in self?.reportMarketOrders()}),
			
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.compact,
						   nodeIdentifier: "IndustryJobs",
						   image: #imageLiteral(resourceName: "industry"),
						   title: NSLocalizedString("Industry Jobs", comment: ""),
						   accessoryType: .disclosureIndicator,
						   route: Router.Custom { [weak self] _,_ in self?.reportIndustryJobs()}),
			
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.compact,
						   nodeIdentifier: "Planetaries",
						   image: #imageLiteral(resourceName: "planets"),
						   title: NSLocalizedString("Planetaries", comment: ""),
						   accessoryType: .disclosureIndicator,
						   route: Router.Custom { [weak self] _,_ in self?.reportPlanetaries()}),
			
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.compact,
						   nodeIdentifier: "Fitting",
						   image: #imageLiteral(resourceName: "fitting"),
						   title: NSLocalizedString("Fitting", comment: ""),
						   accessoryType: .disclosureIndicator,
						   route: Router.Custom { [weak self] _,_ in self?.reportFitting()}),
			
//			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.compact,
//						   nodeIdentifier: "Database",
//						   image: #imageLiteral(resourceName: "items"),
//						   title: NSLocalizedString("Database", comment: ""),
//						   accessoryType: .disclosureIndicator,
//						   route: Router.Custom { [weak self] _,_ in self?.reportDatabase()}),

			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.compact,
						   nodeIdentifier: "Spelling",
						   image: #imageLiteral(resourceName: "notepad"),
						   title: NSLocalizedString("Spelling Error", comment: ""),
						   accessoryType: .disclosureIndicator,
						   route: Router.Custom { [weak self] _,_ in self?.reportSpelling()}),
			
			DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.compact,
						   nodeIdentifier: "Other",
						   image: #imageLiteral(resourceName: "other"),
						   title: NSLocalizedString("Other", comment: ""),
						   accessoryType: .disclosureIndicator,
						   route: Router.Custom { [weak self] _,_ in self?.reportOther()}),

			]
		
		let root = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.static, nodeIdentifier: "Root", title: NSLocalizedString("What kind of problem is this?", comment: "").uppercased(), isExpandable: false, children: rows)
		
		treeController?.content = RootNode([root])
		completionHandler()
	}
	
	lazy var encoder: JSONEncoder = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .formatted(dateFormatter)
		return encoder
	}()
	
	func process<T: Codable> (result: NCCachedResult<T>) -> Data {
		do {
			switch result {
			case let .success(value, _):
				return try encoder.encode(value)
			case let .failure(error):
				throw error
			}
		}
		catch {
			guard let data = error.localizedDescription.data(using: .utf8) else {return "Unknown Error".data(using: .utf8)!}
			return data
		}
	}

	private func reportCharacterSheet() {
		if let account = NCAccount.current {
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 3)
			let dispatchGroup = DispatchGroup()
			let dataManager = NCDataManager(account: account)

			var attachments = [String: Data]()
			
			
			progress.progress.perform {
				dispatchGroup.enter()
				dataManager.character { result in
					attachments["character.json"] = self.process(result: result)
					dispatchGroup.leave()
				}
			}
			
			progress.progress.perform {
				dispatchGroup.enter()
				dataManager.clones { result in
					attachments["clones.json"] = self.process(result: result)
					dispatchGroup.leave()
				}
			}
			
			progress.progress.perform {
				dispatchGroup.enter()
				dataManager.characterLocation { result in
					attachments["characterLocation.json"] = self.process(result: result)
					dispatchGroup.leave()
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				progress.finish()
				Router.MainMenu.BugReport.Finish(attachments: attachments, subject: "Character Sheet").perform(source: self, sender: nil)
			}
		}
		else {
			Router.MainMenu.BugReport.Finish(attachments: [:], subject: "Character Sheet").perform(source: self, sender: nil)
		}
	}
	
	private func reportSkills() {
		if let account = NCAccount.current {
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
			let dispatchGroup = DispatchGroup()
			let dataManager = NCDataManager(account: account)
			
			var attachments = [String: Data]()
			
			
			progress.progress.perform {
				dispatchGroup.enter()
				dataManager.skills { result in
					attachments["skills.json"] = self.process(result: result)
					dispatchGroup.leave()
				}
			}
			
			progress.progress.perform {
				dispatchGroup.enter()
				dataManager.skillQueue { result in
					attachments["skillQueue.json"] = self.process(result: result)
					dispatchGroup.leave()
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				progress.finish()
				Router.MainMenu.BugReport.Finish(attachments: attachments, subject: "Skills").perform(source: self, sender: nil)
			}
		}
		else {
			Router.MainMenu.BugReport.Finish(attachments: [:], subject: "Skills").perform(source: self, sender: nil)
		}
	}
	
	private func reportAssets() {
		if let account = NCAccount.current {
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			let dispatchGroup = DispatchGroup()
			let dataManager = NCDataManager(account: account)
			
			var attachments = [String: Data]()
			
			dispatchGroup.enter()
			func load(page: Int) {
				dataManager.assets(page: page) { result in
					if result.value?.isEmpty == false {
						attachments["assetsPage\(page).json"] = self.process(result: result)
						load(page: page + 1)
					}
					else {
						dispatchGroup.leave()
					}
				}
			}
			load(page: 1)
			
			dispatchGroup.notify(queue: .main) {
				progress.finish()
				Router.MainMenu.BugReport.Finish(attachments: attachments, subject: "Assets").perform(source: self, sender: nil)
			}
		}
		else {
			Router.MainMenu.BugReport.Finish(attachments: [:], subject: "Assets").perform(source: self, sender: nil)
		}
	}
	
	private func reportMarketOrders() {
		if let account = NCAccount.current {
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			let dispatchGroup = DispatchGroup()
			let dataManager = NCDataManager(account: account)
			
			var attachments = [String: Data]()
			
			
			progress.progress.perform {
				dispatchGroup.enter()
				dataManager.marketOrders { result in
					attachments["marketOrders.json"] = self.process(result: result)
					dispatchGroup.leave()
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				progress.finish()
				Router.MainMenu.BugReport.Finish(attachments: attachments, subject: "Market Orders").perform(source: self, sender: nil)
			}
		}
		else {
			Router.MainMenu.BugReport.Finish(attachments: [:], subject: "Market Orders").perform(source: self, sender: nil)
		}
	}
	
	private func reportIndustryJobs() {
		if let account = NCAccount.current {
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			let dispatchGroup = DispatchGroup()
			let dataManager = NCDataManager(account: account)
			
			var attachments = [String: Data]()
			
			
			progress.progress.perform {
				dispatchGroup.enter()
				dataManager.industryJobs { result in
					attachments["industryJobs.json"] = self.process(result: result)
					dispatchGroup.leave()
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				progress.finish()
				Router.MainMenu.BugReport.Finish(attachments: attachments, subject: "Industry Jobs").perform(source: self, sender: nil)
			}
		}
		else {
			Router.MainMenu.BugReport.Finish(attachments: [:], subject: "Industry Jobs").perform(source: self, sender: nil)
		}
	}
	
	private func reportPlanetaries() {
		if let account = NCAccount.current {
			let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
			let dispatchGroup = DispatchGroup()
			let dataManager = NCDataManager(account: account)
			
			var attachments = [String: Data]()
			
			
			progress.progress.perform {
				dispatchGroup.enter()
				dataManager.colonies { result in
					attachments["colonies.json"] = self.process(result: result)
					
					progress.progress.perform {
						if let value = result.value {
							let progress = Progress(totalUnitCount: Int64(value.count))
							for colony in value {
								progress.perform {
									dispatchGroup.enter()
									dataManager.colonyLayout(planetID: colony.planetID) { result in
										attachments["colony\(colony.planetID).json"] = self.process(result: result)
										dispatchGroup.leave()
									}
								}

							}
						}
					}
					
					dispatchGroup.leave()
					
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				progress.finish()
				Router.MainMenu.BugReport.Finish(attachments: attachments, subject: "Planetaries").perform(source: self, sender: nil)
			}
		}
		else {
			Router.MainMenu.BugReport.Finish(attachments: [:], subject: "Planetaries").perform(source: self, sender: nil)
		}
	}
	private func reportFitting() {
		Router.Mail.Attachments { [weak self] (controller, loadout) in
			controller.dismiss(animated: true, completion: nil)
			guard let strongSelf = self else {return}
			guard let loadout = loadout as? NCLoadout else {return}
			guard let data = loadout.data?.data else {return}
			guard let typeName = NCDatabase.sharedDatabase?.invTypes[Int(loadout.typeID)]?.typeName else {return}
			guard let eft = (NCLoadoutRepresentation.eft([(typeID: Int(loadout.typeID), data: data, name: typeName)]).value as? [String])?.first else {return}
			guard let eftData = eft.data(using: .utf8) else {return}
			Router.MainMenu.BugReport.Finish(attachments: ["\(typeName).cfg": eftData], subject: "Fitting").perform(source: strongSelf, sender: nil)
			
		}.perform(source: self, sender: nil)
	}
//	private func reportDatabase() {}
	
	private func reportSpelling() {
		Router.MainMenu.BugReport.Finish(attachments: [:], subject: "Spelling Error").perform(source: self, sender: nil)
	}
	
	private func reportOther() {
		Router.MainMenu.BugReport.Finish(attachments: [:], subject: "Other").perform(source: self, sender: nil)
	}
}
