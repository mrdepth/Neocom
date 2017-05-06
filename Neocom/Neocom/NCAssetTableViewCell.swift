//
//  NCAssetTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

typealias NCAssetTableViewCell = NCDefaultTableViewCell

extension Prototype {
	enum NCAssetTableViewCell {
		static let `default` = Prototype.NCDefaultTableViewCell.compact
		static let container = Prototype(nib: nil, reuseIdentifier: "NCAssetTableViewCell")
	}
}

class NCAssetRow: TreeRow {
	
	let asset: ESI.Assets.Asset
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.asset.typeID]
	}()
	
	lazy var title: String = {
		let title = self.type?.typeName ?? NSLocalizedString("Unknonwn", comment: "")
		if let quantity = self.asset.quantity, quantity > 1 {
			return "\(title) x\(NCUnitFormatter.localizedString(from: quantity, unit: .none, style: .full))"
		}
		else {
			return title
		}
	}()
	
	init(asset: ESI.Assets.Asset, children: [NCAssetRow]?) {
		self.asset = asset
		super.init(prototype: Prototype.NCAssetTableViewCell.default)
		self.children = children
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCAssetTableViewCell else {return}
		let title = type?.typeName ?? NSLocalizedString("Unknonwn", comment: "")
		cell.titleLabel?.text = title
	}
	
	override var hashValue: Int {
		return asset.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCAssetRow)?.hashValue == hashValue
	}
}
