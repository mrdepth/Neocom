//
//  NCWalletTransactionTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCWalletTransactionTableViewCell: NCTableViewCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var priceLabel: UILabel!
	@IBOutlet weak var qtyLabel: UILabel!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
}

extension Prototype {
	enum NCWalletTransactionTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCWalletTransactionTableViewCell")
	}
}

class NCWalletTransactionRow: TreeRow {
	let transaction: EVE.Char.WalletTransactions.Transaction
	let location: NCLocation?
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.transaction.typeID]
	}()
	
	init(transaction: EVE.Char.WalletTransactions.Transaction, location: NCLocation?) {
		self.transaction = transaction
		self.location = location
		
		super.init(prototype: Prototype.NCWalletTransactionTableViewCell.default, route: Router.Database.TypeInfo(transaction.typeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCWalletTransactionTableViewCell else {return}
		cell.titleLabel.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		cell.subtitleLabel.attributedText = location?.displayName ?? NSLocalizedString("Unknown Location", comment: "") * [NSForegroundColorAttributeName: UIColor.lightText]
		cell.iconView.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		
		cell.priceLabel.text = NCUnitFormatter.localizedString(from: transaction.price, unit: .isk, style: .full)
		cell.qtyLabel.text = NCUnitFormatter.localizedString(from: Double(transaction.quantity), unit: .none, style: .full)
		cell.dateLabel.text = DateFormatter.localizedString(from: transaction.transactionDateTime, dateStyle: .medium, timeStyle: .medium)
		
		
		var s = "\(transaction.transactionType == .buy ? "-" : "")\(NCUnitFormatter.localizedString(from: transaction.price * Double(transaction.quantity), unit: .isk, style: .full))" * [NSForegroundColorAttributeName: transaction.transactionType == .buy ? UIColor.red : UIColor.green]
		if !transaction.clientName.isEmpty {
			s = s + " \(transaction.transactionType == .buy ? NSLocalizedString("to", comment: "") : NSLocalizedString("from", comment: "")) \(transaction.clientName)"
		}
		
		cell.amountLabel.attributedText = s
	}
	
	override var hashValue: Int {
		return transaction.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCWalletTransactionRow)?.hashValue == hashValue
	}
}

