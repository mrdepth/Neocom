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

protocol NCWalletJournalItem {
	var amount: Double? {get}
	var balance: Double? {get}
	var date: Date {get}
	var refTypeTitle: String {get}
	var hashValue: Int {get}
}

extension ESI.Wallet.WalletJournalItem: NCWalletJournalItem {
    var refTypeTitle: String {
        return refType.title
    }
}

extension ESI.Wallet.CorpWalletsJournalItem: NCWalletJournalItem {
    var refTypeTitle: String {
        return refType.title
    }
}


class NCWalletJournalRow: TreeRow {
	let item: NCWalletJournalItem
	
	init(item: NCWalletJournalItem) {
		self.item = item
		super.init(prototype: Prototype.NCWalletJournalTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCWalletJournalTableViewCell else {return}
		cell.titleLabel.text = item.refTypeTitle
		cell.dateLabel.text = DateFormatter.localizedString(from: item.date, dateStyle: .medium, timeStyle: .medium)
		var s: NSAttributedString
		if let amount = item.amount {
			s = "\(amount < 0 ? "-" : "")\(NCUnitFormatter.localizedString(from: abs(amount), unit: .isk, style: .full))" * [NSAttributedStringKey.foregroundColor: amount < 0 ? UIColor.red : UIColor.green]
		}
		else {
			s = NSAttributedString()
		}
		
		cell.amountLabel.attributedText = s
		if let balance = item.balance {
			cell.balanceLabel.text = NCUnitFormatter.localizedString(from: balance, unit: .isk, style: .full)
		}
		else {
			cell.balanceLabel.text = nil
		}
	}
	
	override var hash: Int {
        return item.hashValue
    }
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCWalletJournalRow)?.hashValue == hashValue
	}
	
}

