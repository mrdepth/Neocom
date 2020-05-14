//
//  WalletJournalCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import TreeController

class WalletJournalCell: RowCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
}

extension Prototype {
	enum WalletJournalCell {
		static let `default` = Prototype(nib: UINib(nibName: "WalletJournalCell", bundle: nil), reuseIdentifier: "WalletJournalCell")
	}
}

extension ESI.Wallet.WalletJournalItem: CellConfigurable {
	var prototype: Prototype? {
		return Prototype.WalletJournalCell.default
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? WalletJournalCell else {return}
		
		cell.titleLabel.text = refType.title
		cell.dateLabel.text = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
		var s: NSAttributedString
		if let amount = amount {
			s = "\(amount < 0 ? "-" : "")\(UnitFormatter.localizedString(from: abs(amount), unit: .isk, style: .long))" * [NSAttributedString.Key.foregroundColor: amount < 0 ? UIColor.red : UIColor.green]
		}
		else {
			s = NSAttributedString()
		}
		
		cell.amountLabel.attributedText = s
		if let balance = balance {
			cell.balanceLabel.text = UnitFormatter.localizedString(from: balance, unit: .isk, style: .long)
		}
		else {
			cell.balanceLabel.text = nil
		}
	}
	
	
}
