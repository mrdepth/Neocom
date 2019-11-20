//
//  IncursionCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import TreeController

class IncursionCell: RowCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var bossImageView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var stateLabel: UILabel!
	@IBOutlet weak var progressLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		let layer = self.progressView.superview?.layer;
		layer?.borderColor = UIColor(number: 0x3d5866ff).cgColor
		layer?.borderWidth = 1.0 / UIScreen.main.scale
	}
}


extension Prototype {
	enum IncursionCell {
		static let `default` = Prototype(nib: UINib(nibName: "IncursionCell", bundle: nil), reuseIdentifier: "IncursionCell")
	}
}

extension Tree.Item {
	class IncursionRow: ExpandableRow<ESI.Incursions.Incursion, Tree.Item.RoutableRow<SDEMapSolarSystem>> {
		let api: API
		
		init(_ content: ESI.Incursions.Incursion, api: API) {
			self.api = api
			
			let context = Services.sde.viewContext
			
			//TODO: add route
			let rows = content.infestedSolarSystems.compactMap { context.mapSolarSystem($0) }.map {
				Tree.Item.RoutableRow($0)
			}
			super.init(content, isExpanded: false, children: rows)
		}
		
		override var prototype: Prototype? {
			return Prototype.IncursionCell.default
		}
		
		lazy var solaySystem: EVELocation? = {
			guard let solarSystem = Services.sde.viewContext.mapSolarSystem(content.stagingSolarSystemID) else {return nil}
			return EVELocation(solarSystem)
		}()

		lazy var title: String = {
			if let constellation = Services.sde.viewContext.mapConstellation(content.constellationID) {
				return "\(constellation.constellationName ?? "") / \(constellation.region?.regionName ?? "")"
			}
			else {
				return NSLocalizedString("Unknown", comment: "")
			}
		}()

		var image: UIImage?
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? IncursionCell else {return}
			
			cell.titleLabel.text = title
			cell.bossImageView.alpha = content.hasBoss ? 1.0 : 0.4
			cell.progressView.progress = content.influence
			cell.progressLabel.text = NSLocalizedString("Warzone Control: ", comment: "") + "\(Int((content.influence * 100).rounded(.down)))%"
			cell.locationLabel.attributedText = solaySystem?.displayName
			cell.stateLabel.text = content.state.title
			
			cell.iconView.image = image
			
			if image == nil {
				api.image(allianceID: Int64(content.factionID), dimension: Int(cell.iconView.bounds.size.width), cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self, weak treeController] result in
					guard let strongSelf = self else {return}
					strongSelf.image = result.value
					if let cell = treeController?.cell(for: strongSelf) as? IncursionCell {
						cell.iconView.image = strongSelf.image
					}
				}.catch(on: .main) { [weak self] _ in
					self?.image = UIImage()
				}
			}
		}
	}
}
