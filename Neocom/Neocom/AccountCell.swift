//
//  AccountCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import EVEAPI

class AccountCell: RowCell {
	@IBOutlet weak var characterNameLabel: UILabel?
	@IBOutlet weak var characterImageView: UIImageView?
	@IBOutlet weak var corporationLabel: UILabel?
	@IBOutlet weak var spLabel: UILabel?
	@IBOutlet weak var wealthLabel: UILabel?
	@IBOutlet weak var locationLabel: UILabel?
	@IBOutlet weak var skillLabel: UILabel?
	@IBOutlet weak var trainingTimeLabel: UILabel?
	@IBOutlet weak var skillQueueLabel: UILabel?
	@IBOutlet weak var trainingProgressView: UIProgressView?
	@IBOutlet weak var alertLabel: UILabel?
	
//	var progressHandler: NCProgressHandler?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		let layer = self.trainingProgressView?.superview?.layer;
		layer?.borderColor = UIColor(number: 0x3d5866ff).cgColor
		layer?.borderWidth = 1.0 / UIScreen.main.scale
	}
}

extension Prototype {
	enum AccountCell {
		static let `default` = Prototype(nib: UINib(nibName: "AccountCell", bundle: nil), reuseIdentifier: "AccountCell")
	}
}

extension Tree.Item {
	
	class AccountsItem: FetchedResultsRow<Account>, CellConfiguring {
		
		var prototype: Prototype? { return Prototype.AccountCell.default }
		lazy var api: API = Services.api.make(for: self.result)
		
		var character: Future<ESI.Result<ESI.Character.Information>>?
		var corporation: Future<ESI.Result<ESI.Corporation.Information>>?
		var skillQueue: Future<ESI.Result<[ESI.Skills.SkillQueueItem]>>?
		var skills: Future<ESI.Result<ESI.Skills.CharacterSkills>>?
		var walletBalance: Future<ESI.Result<Double>>?
		var location: Future<String?>?
		var ship: Future<String?>?
		var image: Future<ESI.Result<UIImage>>?
		var cachePolicy: URLRequest.CachePolicy {
			return (section.controller as! AccountsResultsController).cachePolicy
		}
		
		override func isEqual(_ other: Tree.Item.FetchedResultsRow<Account>) -> Bool {
			guard let other = other as? AccountsItem else {return false}
			return super.isEqual(other) && cachePolicy == other.cachePolicy
		}
		
		var isOAuth2TokenInvalid: Bool {
			return result.refreshToken?.isEmpty != false
		}
		
		func configure(cell: UITableViewCell) {
			guard let cell = cell as? AccountCell else {return}
			
			if isOAuth2TokenInvalid {
				cell.characterNameLabel?.text = result.characterName
				cell.corporationLabel?.text = NSLocalizedString("Access Token did become invalid", comment: "")
				cell.corporationLabel?.textColor = .red
				if state == .initial {
					load(options: [.image])
				}
				else {
					cell.characterImageView?.image = (try? image?.tryGet()?.value) ?? #imageLiteral(resourceName: "avatar")
				}
				cell.alertLabel?.isHidden = true
			}
			else {
				if let scopes = result.scopes?.compactMap({($0 as? Scope)?.name}), Set(ESI.Scope.default.map{$0.rawValue}).isSubset(of: Set(scopes)) {
					cell.alertLabel?.isHidden = true
				}
				else {
					cell.alertLabel?.isHidden = false
				}

				
				if state == .initial {
					cell.characterNameLabel?.text = result.characterName
					cell.characterImageView?.image = #imageLiteral(resourceName: "avatar")
					cell.spLabel?.text = " "
					cell.wealthLabel?.text = " "
					cell.locationLabel?.text = " "
					cell.skillLabel?.text = " "
					cell.trainingTimeLabel?.text = " "
					cell.skillQueueLabel?.text = " "
					cell.trainingProgressView?.progress = 0
					cell.alertLabel?.text = " "
					
					
					var options = LoadingOptions()
					if cell.corporationLabel != nil {
						options.insert(.characterInfo)
						options.insert(.corporationInfo)
					}
					if cell.skillQueueLabel != nil {
						options.insert(.skillQueue)
					}
					if cell.skillLabel != nil {
						options.insert(.skills)
					}
					if cell.wealthLabel != nil {
						options.insert(.walletBalance)
					}
					if cell.locationLabel != nil{
						options.insert(.characterLocation)
						options.insert(.characterShip)
					}
					if cell.imageView != nil {
						options.insert(.image)
					}
					load(options: options)
				} else {
					cell.characterNameLabel?.text = (try? character?.tryGet()?.value.name) ?? result.characterName
					cell.characterImageView?.image = (try? image?.tryGet()?.value) ?? #imageLiteral(resourceName: "avatar")
					
					do {
						try cell.corporationLabel?.text = corporation?.tryGet()?.value.name
						cell.corporationLabel?.textColor = .white
					}
					catch {
						cell.corporationLabel?.text = error.localizedDescription
						cell.corporationLabel?.textColor = .red
					}

					cell.spLabel?.text = {
						do {
							guard let value = try skills?.tryGet()?.value else {return " "}
							return UnitFormatter.localizedString(from: value.totalSP, unit: .none, style: .short)
						}
						catch {
							return error.localizedDescription
						}
					}()
					
					cell.wealthLabel?.text = {
						do {
							guard let value = try walletBalance?.tryGet()?.value else {return " "}
							return UnitFormatter.localizedString(from: value, unit: .none, style: .short)
						}
						catch {
							return error.localizedDescription
						}
					}()
					
					cell.locationLabel?.attributedText = {
						do {
							let location = try self.location?.tryGet() ?? nil
							let ship = try self.ship?.tryGet() ?? nil
							let components = [location.map {NSAttributedString(string: $0, attributes: [.foregroundColor : UIColor.white])},
											  ship.map {NSAttributedString(string: $0, attributes: [.foregroundColor : UIColor.lightText])}].compactMap{$0}
							guard !components.isEmpty else {return NSAttributedString(string: " ")}
							return components.joined(separator: NSAttributedString(string: ", ", attributes: [.foregroundColor : UIColor.white]))
						}
						catch {
							return NSAttributedString(string: error.localizedDescription, attributes: [.foregroundColor : UIColor.white])
						}
					}()
					
					do {
						if let value = try self.skillQueue?.tryGet()?.value {
							let currentDate = Date()
							let skillQueue = value.filter { $0.finishDate != nil && $0.finishDate! > currentDate }
							let firstSkill = skillQueue.first { $0.finishDate! > currentDate }

							let trainingTime: String
							let trainingProgress: Float
							let title: NSAttributedString
							if let firstSkill = firstSkill {
								
								if let type = Services.sde.viewContext.invType(firstSkill.skillID),
									let skill = Character.Skill(type: type) {
									let firstTrainingSkill = Character.SkillQueueItem(skill: skill, queuedSkill: firstSkill)
//									firstTrainingSkill.queuedSkill.finishedLevel
									title = NSAttributedString(skillName: type.typeName ?? "", level: firstSkill.finishedLevel)
									trainingProgress = firstTrainingSkill.trainingProgress
									
								}
								else {
									title = NSAttributedString(string: String(format: NSLocalizedString("Unknown skill %d", comment: ""), firstSkill.skillID))
									trainingProgress = 0
								}
								
								if let finishDate = firstSkill.finishDate {
									trainingTime = TimeIntervalFormatter.localizedString(from: finishDate.timeIntervalSinceNow, precision: .minutes)
								}
								else {
									trainingTime = " "
								}
							}
							else {
								title = NSAttributedString(string: NSLocalizedString("No skills in training", comment: ""), attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightText])
								trainingProgress = 0
								trainingTime = " "
							}
							
							let skillQueueText: String
							
							if let skill = skillQueue.last, let endTime = skill.finishDate {
								skillQueueText = String(format: NSLocalizedString("%d skills in queue (%@)", comment: ""), skillQueue.count, TimeIntervalFormatter.localizedString(from: endTime.timeIntervalSinceNow, precision: .minutes))
							}
							else {
								skillQueueText = " "
							}
							
							
							cell.skillLabel?.attributedText = title
							cell.trainingTimeLabel?.text = trainingTime
							cell.trainingProgressView?.progress = trainingProgress
							cell.skillQueueLabel?.text = skillQueueText
							
						}
						else {
							cell.skillLabel?.text = " "
							cell.skillQueueLabel?.text = " "
							cell.trainingTimeLabel?.text = " "
							cell.trainingProgressView?.progress = 0
						}
					}
					catch {
						cell.skillLabel?.text = error.localizedDescription
						cell.skillQueueLabel?.text = " "
						cell.trainingTimeLabel?.text = " "
						cell.trainingProgressView?.progress = 0
					}
				}
			}
		}
		
		private enum State {
			case initial
			case loading
			case loaded
		}
		
		private struct LoadingOptions: OptionSet {
			var rawValue: Int
			static let characterInfo = LoadingOptions(rawValue: 1 << 0)
			static let corporationInfo = LoadingOptions(rawValue: 1 << 1)
			static let skillQueue = LoadingOptions(rawValue: 1 << 2)
			static let skills = LoadingOptions(rawValue: 1 << 3)
			static let walletBalance = LoadingOptions(rawValue: 1 << 4)
			static let characterLocation = LoadingOptions(rawValue: 1 << 5)
			static let characterShip = LoadingOptions(rawValue: 1 << 6)
			static let image = LoadingOptions(rawValue: 1 << 7)
			var count: Int {
				return sequence(first: rawValue) {$0 > 1 ? $0 >> 1 : nil}.reduce(0) {
					$0 + (($1 & 1) == 1 ? 1 : 0)
				}
			}
		}
		
		private var state = State.initial
		private func load(options: LoadingOptions) {
			let cachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
			guard state == .initial else {return}
			state = .loading
			
			let progress: ProgressTask?
			if let cell = section.controller.treeController?.cell(for: self) {
				progress = ProgressTask(totalUnitCount: Int64(options.count), indicator: .progressBar(cell))
			}
			else {
				progress = nil
			}
			
			func perform<ReturnType>(using work: () throws -> ReturnType) rethrows -> ReturnType {
				if let progress = progress {
					return try progress.performAsCurrent(withPendingUnitCount: 1, using: work)
				}
				else {
					return try work()
				}
			}
	

			let characterID = result.characterID

			DispatchQueue.global(qos: .utility).async { [weak self, weak api] () -> Void in
				guard let character = perform(using: {api?.characterInformation(cachePolicy: cachePolicy)}) else {return}
				
				character.finally(on: .main) {
					self?.character = character
					self?.update()
				}
				
				if options.contains(.corporationInfo), let corporationID = try? character.get().value.corporationID {
					let corporation = perform{api?.corporationInformation(corporationID: Int64(corporationID), cachePolicy: cachePolicy)}
					corporation?.finally(on: .main) {
						self?.corporation = corporation
						self?.update()
					}
				}
				
				if options.contains(.skillQueue) {
					let skillQueue = perform{api?.skillQueue(cachePolicy: cachePolicy)}
					skillQueue?.finally(on: .main) {
						self?.skillQueue = skillQueue
						self?.update()
					}
				}
				
				if options.contains(.skills) {
					let skills = perform{api?.skills(cachePolicy: cachePolicy)}
					skills?.finally(on: .main) {
						self?.skills = skills
						self?.update()
					}
				}

				if options.contains(.walletBalance) {
					let walletBalance = perform{api?.walletBalance(cachePolicy: cachePolicy)}
					walletBalance?.finally(on: .main) {
						self?.walletBalance = walletBalance
						self?.update()
					}
				}

				if options.contains(.characterLocation) {
					let characterLocation = perform {
						api?.characterLocation(cachePolicy: cachePolicy).then { value in
							Services.sde.performBackgroundTask { context -> String? in
								guard let solarSystem = context.mapSolarSystem(value.value.solarSystemID) else {return nil}
								return "\(solarSystem.solarSystemName ?? "") / \(solarSystem.constellation?.region?.regionName ?? "")"
							}
						}
					}
					
					characterLocation?.finally(on: .main) {
						self?.location = characterLocation
						self?.update()
					}
				}

				if options.contains(.characterLocation) {
					let characterShip = perform{
						api?.characterShip(cachePolicy: cachePolicy).then {value in
							Services.sde.performBackgroundTask { context -> String? in
								guard let type = context.invType(value.value.shipTypeID) else {return nil}
								return type.typeName
							}
						}
					}
					characterShip?.finally(on: .main) {
						self?.ship = characterShip
						self?.update()
					}
				}

				if options.contains(.image) {
					let image = perform{api?.image(characterID: characterID, dimension: 64, cachePolicy: cachePolicy)}
					image?.finally(on: .main) {
						self?.image = image
						self?.update()
					}
				}
			}.finally(on: .main) { [weak self] in
				self?.state = .loaded
			}
		}
		
		private func update() {
			section.controller.treeController?.reloadRow(for: self, with: .none)
		}
	}
}
