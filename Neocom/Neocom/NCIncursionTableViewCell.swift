//
//  NCIncursionTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCIncursionTableViewCell: NCTableViewCell {
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
	enum NCIncursionTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCIncursionTableViewCell")
	}
}

class NCIncursionRow: TreeRow {
	
	let incursion: ESI.Incursions.Incursion
	let contact: NCContact?
	
	init(incursion: ESI.Incursions.Incursion, contact: NCContact?) {
		self.incursion = incursion
		self.contact = contact
		super.init(prototype: Prototype.NCIncursionTableViewCell.default)
	}
	
	lazy var title: String = {
		if let constellation = NCDatabase.sharedDatabase?.mapConstellations[self.incursion.constellationID] {
			return "\(constellation.constellationName ?? "") / \(constellation.region?.regionName ?? "")"
		}
		else {
			return NSLocalizedString("Unknown", comment: "")
		}
	}()
	
	lazy var solaySystem: NCLocation? = {
		guard let solarSystem = NCDatabase.sharedDatabase?.mapSolarSystems[self.incursion.stagingSolarSystemID] else {return nil}
		return NCLocation(solarSystem)
	}()
	
	private var image: UIImage?
	
	override func configure(cell: UITableViewCell) {
		
		guard let cell = cell as? NCIncursionTableViewCell else {return}
		cell.object = incursion
		cell.titleLabel.text = title
		cell.bossImageView.alpha = incursion.hasBoss ? 1.0 : 0.4
		cell.progressView.progress = incursion.influence
		cell.progressLabel.text = NSLocalizedString("Warzone Control: ", comment: "") + "\(Int((incursion.influence * 100).rounded(.down)))%"
		cell.locationLabel.attributedText = solaySystem?.displayName
		cell.stateLabel.text = incursion.state.title
		
		cell.iconView.image = image
		if image == nil {
			NCDataManager().image(allianceID: Int64(incursion.factionID), dimension: Int(cell.iconView.bounds.size.width)) { result in
				self.image = result.value ?? UIImage()
				if (cell.object as? ESI.Incursions.Incursion) == self.incursion {
					cell.iconView.image = self.image
				}
			}
		}
	}
	
	override lazy var hashValue: Int = incursion.hashValue
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCIncursionRow)?.hashValue == hashValue
	}
}
