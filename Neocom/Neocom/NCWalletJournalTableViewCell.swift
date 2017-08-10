//
//  NCWalletJournalTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCWalletJournalTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	
}

extension Prototype {
	enum NCWalletJournalTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCWalletJournalTableViewCell")
	}
}

class NCWalletJournalRow: TreeRow {
	let transaction: EVE.Char.WalletJournal.Transaction
	let refType: EVE.Eve.RefTypes.RefType?
	
	init(transaction: EVE.Char.WalletJournal.Transaction, refType: EVE.Eve.RefTypes.RefType?) {
		self.transaction = transaction
		self.refType = refType
		super.init(prototype: Prototype.NCWalletJournalTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCWalletJournalTableViewCell else {return}
		cell.titleLabel.text = refType?.refTypeName ?? NSLocalizedString("Unknown", comment: "")
		cell.dateLabel.text = DateFormatter.localizedString(from: transaction.date, dateStyle: .medium, timeStyle: .medium)
		var s = "\(transaction.amount < 0 ? "-" : "")\(NCUnitFormatter.localizedString(from: abs(transaction.amount), unit: .isk, style: .full))" * [NSForegroundColorAttributeName: transaction.amount < 0 ? UIColor.red : UIColor.green]
		
		if let to = transaction.ownerName2, transaction.amount < 0 && !to.isEmpty {
			s = s + " \(NSLocalizedString("to", comment: "")) \(to)"
		}
		else if let from = transaction.ownerName1, transaction.amount > 0 && !from.isEmpty {
			s = s + " \(NSLocalizedString("from", comment: "")) \(from)"
		}
		
		cell.amountLabel.attributedText = s
		cell.balanceLabel.text = NCUnitFormatter.localizedString(from: abs(transaction.balance), unit: .isk, style: .full)
	}
	
	override var hashValue: Int {
		return transaction.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCWalletJournalRow)?.hashValue == hashValue
	}
	
}

