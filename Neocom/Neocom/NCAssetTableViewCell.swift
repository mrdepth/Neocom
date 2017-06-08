//
//  NCAssetTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCAssetTableViewCell: NCDefaultTableViewCell, Expandable {
	@IBOutlet weak var expandIconView: UIImageView?

	func setExpanded(_ expanded: Bool, animated: Bool) {
		expandIconView?.image = expanded ? #imageLiteral(resourceName: "collapse") : #imageLiteral(resourceName: "expand")
	}
}

extension Prototype {
	enum NCAssetTableViewCell {
		static let `default` = Prototype.NCDefaultTableViewCell.compact
		static let container = Prototype(nib: nil, reuseIdentifier: "NCAssetTableViewCell")
	}
}

class NCAssetRow: DefaultTreeRow {
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		if image == nil {
			(cell as? NCAssetTableViewCell)?.iconView?.image = NCDBEveIcon.defaultType.image?.image
		}
	}
	
	override var isExpandable: Bool {
		return true
	}
	
//	let asset: ESI.Assets.Asset
//	lazy var type: NCDBInvType? = {
//		return NCDatabase.sharedDatabase?.invTypes[self.asset.typeID]
//	}()
//	
//	lazy var title: String = {
//		let title = self.type?.typeName ?? NSLocalizedString("Unknonwn", comment: "")
//		if let quantity = self.asset.quantity, quantity > 1 {
//			return "\(title) x\(NCUnitFormatter.localizedString(from: quantity, unit: .none, style: .full))"
//		}
//		else {
//			return title
//		}
//	}()
//	
//	init(asset: ESI.Assets.Asset, children: [NCAssetRow]?) {
//		self.asset = asset
//		super.init(prototype: Prototype.NCAssetTableViewCell.default)
//		self.children = children
//	}
//	
//	override func configure(cell: UITableViewCell) {
//		guard let cell = cell as? NCAssetTableViewCell else {return}
//		let title = type?.typeName ?? NSLocalizedString("Unknonwn", comment: "")
//		cell.titleLabel?.text = title
//	}
	
}
