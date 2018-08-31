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
	
	class AccountsItem: FetchedResultsItem<Account>, CellConfiguring {
		
		var prototype: Prototype? { return Prototype.TreeHeaderCell.default }
		lazy var api: API = Services.api.make(for: self.content)
		
		var character: Future<ESI.Result<ESI.Character.Information>>?
		var corporation: Future<ESI.Result<ESI.Corporation.Information>>?
		var skillQueue: Future<ESI.Result<[ESI.Skills.SkillQueueItem]>>?
		var skills: Future<ESI.Result<ESI.Skills.CharacterSkills>>?
		var walletBalance: Future<ESI.Result<Double>>?
		var location: Future<ESI.Result<ESI.Location.CharacterLocation>>?
		var ship: Future<ESI.Result<ESI.Location.CharacterShip>>?
		var image: Future<ESI.Result<UIImage>>?
		
		var isOAuth2TokenInvalid: Bool {
			return content.refreshToken?.isEmpty != false
		}
		
		func configure(cell: UITableViewCell) {
			guard let cell = cell as? AccountCell else {return}
			
			if isOAuth2TokenInvalid {
				cell.characterNameLabel?.text = content.characterName
				cell.corporationLabel?.text = NSLocalizedString("Access Token did become invalid", comment: "")
				cell.corporationLabel?.textColor = .red
				
			}
			
			
			if state == .initial {
				cell.characterImageView?.image = nil
				cell.spLabel?.text = " "
				cell.wealthLabel?.text = " "
				cell.locationLabel?.text = " "
				cell.skillLabel?.text = " "
				cell.trainingTimeLabel?.text = " "
				cell.skillQueueLabel?.text = " "
				cell.trainingProgressView?.progress = 0
				cell.alertLabel?.text = " "

				if isOAuth2TokenInvalid {
					load(options: [.image])
				}
				else {
					cell.characterNameLabel?.text = (try? character?.tryGet()?.value.name) ?? content.characterName
					
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
				}
			} else {
				try? cell.characterImageView?.image = image?.tryGet()?.value
				
				if !isOAuth2TokenInvalid {
					do {
						try cell.corporationLabel?.text = corporation?.tryGet()?.value.name
						cell.corporationLabel?.textColor = .white
					}
					catch {
						cell.corporationLabel?.text = error.localizedDescription
						cell.corporationLabel?.textColor = .red
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
			if let cell = section?.controller?.treeController?.cell(for: self) {
				progress = ProgressTask(progress: Progress(totalUnitCount: Int64(options.count)), indicator: .progressBar(cell))
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
	

			let characterID = content.characterID

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
					let characterLocation = perform{api?.characterLocation(cachePolicy: cachePolicy)}
					characterLocation?.finally(on: .main) {
						self?.location = characterLocation
						self?.update()
					}
				}

				if options.contains(.characterLocation) {
					let characterShip = perform{api?.characterShip(cachePolicy: cachePolicy)}
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
			section?.controller?.treeController?.reloadRow(for: self, with: .none)
		}
	}
}
