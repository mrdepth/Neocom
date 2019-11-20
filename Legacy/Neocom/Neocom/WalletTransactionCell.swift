//
//  WalletTransactionCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import TreeController

class WalletTransactionCell: RowCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var priceLabel: UILabel!
	@IBOutlet weak var qtyLabel: UILabel!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
}

extension Prototype {
	enum WalletTransactionCell {
		static let `default` = Prototype(nib: UINib(nibName: "WalletTransactionCell", bundle: nil), reuseIdentifier: "WalletTransactionCell")
	}
}

extension Tree.Item {
	class WalletTransactionRow: RoutableRow<ESI.Wallet.Transaction> {
		
		var client: Contact?
		var location: EVELocation
		lazy var type: SDEInvType? = Services.sde.viewContext.invType(content.typeID)
		
		override var prototype: Prototype? {
			return Prototype.WalletTransactionCell.default
		}
		
		init(_ content: ESI.Wallet.Transaction, client: Contact?, location: EVELocation) {
			self.client = client
			self.location = location
			super.init(content)
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? WalletTransactionCell else {return}
			
			cell.titleLabel.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
			cell.subtitleLabel.attributedText = location.displayName
			cell.iconView.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
			
			cell.priceLabel.text = UnitFormatter.localizedString(from: content.unitPrice, unit: .isk, style: .long)
			cell.qtyLabel.text = UnitFormatter.localizedString(from: Double(content.quantity), unit: .none, style: .long)
			cell.dateLabel.text = DateFormatter.localizedString(from: content.date, dateStyle: .medium, timeStyle: .medium)

			var s = "\(content.isBuy ? "-" : "")\(UnitFormatter.localizedString(from: content.unitPrice * Double(content.quantity), unit: .isk, style: .long))" * [NSAttributedString.Key.foregroundColor: content.isBuy ? UIColor.red : UIColor.green]
			if let client = client?.name {
				s = s + " \(content.isBuy ? NSLocalizedString("to", comment: "") : NSLocalizedString("from", comment: "")) \(client)"
			}
			
			cell.amountLabel.attributedText = s

		}
	}
}
