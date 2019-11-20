//
//  KillmailCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/13/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import TreeController
import Futures

class KillmailCell: RowCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var solarSystemLabel: UILabel!
}

extension Prototype {
	enum KillmailCell {
		static let `default` = Prototype(nib: UINib(nibName: "KillmailCell", bundle: nil), reuseIdentifier: "KillmailCell")
	}
}

extension Tree.Item {
	class KillmailRow: RoutableRow<ESI.Killmails.Killmail> {
		lazy var type: SDEInvType? = Services.sde.viewContext.invType(content.victim.shipTypeID)
		lazy var location: EVELocation = Services.sde.viewContext.mapSolarSystem(content.solarSystemID).map{EVELocation($0)} ?? .unknown
		var name: Contact?
		
		override var prototype: Prototype? {
			return Prototype.KillmailCell.default
		}
		
		init(_ content: ESI.Killmails.Killmail, name: Contact?) {
			self.name = name
			super.init(content, route: Router.KillReports.killmailInfo(content))
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? KillmailCell else {return}
			
			cell.iconView?.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
			cell.titleLabel?.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
			cell.dateLabel.text = DateFormatter.localizedString(from: content.killmailTime, dateStyle: .none, timeStyle: .medium)
			cell.solarSystemLabel.attributedText = location.displayName + " (\(String(format: NSLocalizedString("%@ involved", comment: ""), UnitFormatter.localizedString(from: content.attackers.count, unit: .none, style: .long))))"
			cell.subtitleLabel.text = name?.name ?? NSLocalizedString("Unknown", comment: "")
		}
	}
	
	class ZKillmailRow: RoutableRow<EVEAPI.ZKillboard.Killmail> {
		var killmailDetails: Future<ESI.Result<Value>>?
		
		class Value {
			lazy var type: SDEInvType? = Services.sde.viewContext.invType(killmailInfo.victim.shipTypeID)
			lazy var location: EVELocation = Services.sde.viewContext.mapSolarSystem(killmailInfo.solarSystemID).map{EVELocation($0)} ?? .unknown
			
			var killmailInfo: ESI.Killmails.Killmail
			var name: Contact?
			init(killmailInfo: ESI.Killmails.Killmail, name: Contact?) {
				self.killmailInfo = killmailInfo
				self.name = name
			}
		}
		
		override var prototype: Prototype? {
			return Prototype.KillmailCell.default
		}
		
		var api: API
		
		init(_ content: EVEAPI.ZKillboard.Killmail, api: API) {
			self.api = api
			super.init(content)
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? KillmailCell else {return}
			
			let api = self.api
			
			cell.iconView?.image = UIImage()
			cell.titleLabel?.text = " "
			cell.dateLabel.text = " "
			cell.solarSystemLabel.text = " "
			cell.subtitleLabel.text = " "

			
			if killmailDetails == nil {
				let content = self.content
				
				let progress: ProgressTask?
				if let cell = treeController?.cell(for: self) {
					progress = ProgressTask(totalUnitCount: Int64(2), indicator: .progressBar(cell))
				}
				else {
					progress = nil
				}
				
				func perform<ReturnType>(using work: () throws -> ReturnType) rethrows -> ReturnType {
					if let progress = progress {
						return try progress.performAsCurrent(withPendingUnitCount: 2, using: work)
					}
					else {
						return try work()
					}
				}
				
				killmailDetails = DispatchQueue.global(qos: .utility).async { () -> ESI.Result<Value> in
					
					let killmail = try perform {api.killmailInfo(killmailHash: content.hash, killmailID: content.killmailID, cachePolicy: .useProtocolCachePolicy)}.get()
					let contact = (try? perform{(killmail.value.victim.characterID ?? killmail.value.victim.corporationID ?? killmail.value.victim.allianceID).map {api.contacts(with: Set([Int64($0)]))}}?.get().first?.value) ?? nil
					return killmail.map {Value(killmailInfo: $0, name: contact)}
				}.then(on: .main) { [weak self] result -> ESI.Result<Value> in
					self?.route = Router.KillReports.killmailInfo(result.value.killmailInfo)
					return result
				}.finally(on: .main) { [weak self] in
					guard let strongSelf = self else {return}
					treeController?.reloadRow(for: strongSelf, with: .fade)
				}
			}
			else {
				do {
					if let value = try killmailDetails?.tryGet()?.value {
						cell.iconView?.image = value.type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
						cell.titleLabel?.text = value.type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
						cell.dateLabel.text = DateFormatter.localizedString(from: value.killmailInfo.killmailTime, dateStyle: .medium, timeStyle: .medium)
						cell.solarSystemLabel.attributedText = value.location.displayName + " (\(String(format: NSLocalizedString("%@ involved", comment: ""), UnitFormatter.localizedString(from: value.killmailInfo.attackers.count, unit: .none, style: .long))))"
						cell.subtitleLabel.text = value.name?.name ?? NSLocalizedString("Unknown", comment: "")
					}
				}
				catch {
					cell.titleLabel.text = error.localizedDescription
				}
			}
			
		}
	}
}
