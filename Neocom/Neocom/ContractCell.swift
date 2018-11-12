//
//  ContractCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import TreeController

class ContractCell: RowCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var stateLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
}

extension Prototype {
	enum ContractCell {
		static let `default` = Prototype(nib: UINib(nibName: "ContractCell", bundle: nil), reuseIdentifier: "ContractCell")
	}
}

extension Tree.Content {
	struct Contract: Hashable {
		var prototype: Prototype? = Prototype.ContractCell.default
		var contract: ESI.Contracts.Contract
		var issuer: Contact?
		var location: EVELocation
		var endDate: Date
		var characterID: Int64
	}
	
}

extension Tree.Content.Contract: CellConfiguring {
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? ContractCell else {return}
		let type = contract.type.title
		
		let availability = contract.availability.title
		
		let t = contract.dateExpired.timeIntervalSinceNow
		
		let status = contract.currentStatus
		
		let color = status == .outstanding || status == .inProgress ? UIColor.white : UIColor.lightText
		
		if status == .outstanding || status == .inProgress {
			cell.titleLabel.attributedText = type * [NSAttributedString.Key.foregroundColor: color] + " [\(availability)]" * [NSAttributedString.Key.foregroundColor: UIColor.caption]
		}
		else {
			cell.titleLabel.attributedText = "\(type) [\(availability)]" * [NSAttributedString.Key.foregroundColor: color]
		}
		
		cell.subtitleLabel.text = contract.title
		cell.locationLabel.attributedText = location.displayName
		
		switch status {
		case .outstanding, .inProgress:
			cell.stateLabel.attributedText = status.title * [NSAttributedString.Key.foregroundColor: color] + " " + TimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes) * [NSAttributedString.Key.foregroundColor: UIColor.lightText]
		default:
			cell.stateLabel.attributedText = "\(status.title) \(DateFormatter.localizedString(from: endDate, dateStyle: .medium, timeStyle: .medium))" * [NSAttributedString.Key.foregroundColor: UIColor.lightText]
		}
		
		if contract.issuerID == Int(characterID) {
			cell.dateLabel.text = DateFormatter.localizedString(from: contract.dateIssued, dateStyle: .medium, timeStyle: .medium)
		}
		else if let issuer = issuer?.name {
			cell.dateLabel.text = "\(DateFormatter.localizedString(from: contract.dateIssued, dateStyle: .medium, timeStyle: .medium)) \(NSLocalizedString("by", comment: "")) \(issuer)"
		}
	}
}
