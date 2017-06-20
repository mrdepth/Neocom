//
//  NCContractTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCContractTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var stateLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
}

extension Prototype {
	enum NCContractTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCContractTableViewCell")
	}
}

class NCContractRow: TreeRow {
	let contract: ESI.Contracts.Contract
	let contacts: [Int64: NCContact]?
	let location: NCLocation?
	let endDate: Date
	let characterID: Int64
	
	init(contract: ESI.Contracts.Contract, characterID: Int64, contacts: [Int64: NCContact]?, location: NCLocation?) {
		self.contract = contract
		self.characterID = characterID
		self.contacts = contacts
		self.location = location
		endDate = contract.dateCompleted ?? {
			guard let date = contract.dateAccepted, let duration = contract.daysToComplete else {return nil}
			return date.addingTimeInterval(TimeInterval(duration) * 24 * 3600)
		}() ?? contract.dateExpired
		
		super.init(prototype: Prototype.NCContractTableViewCell.default, route: nil)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCContractTableViewCell else {return}
		
		let type: String
		switch contract.type {
		case .auction:
			type = NSLocalizedString("Auction", comment: "")
		case .courier:
			type = NSLocalizedString("Courier", comment: "")
		case .itemExchange:
			type = NSLocalizedString("Item Exchange", comment: "")
		case .loan:
			type = NSLocalizedString("Loan", comment: "")
		case .unknown:
			type = NSLocalizedString("Unknown", comment: "")
		}
		
		let availability: String
		switch contract.availability {
		case .alliance:
			availability = NSLocalizedString("Alliance", comment: "")
		case .corporation:
			availability = NSLocalizedString("Corporation", comment: "")
		case .personal:
			availability = NSLocalizedString("Personal", comment: "")
		case .public:
			availability = NSLocalizedString("Public", comment: "")
		}
		
		let color = contract.status == .outstanding || contract.status == .inProgress ? UIColor.white : UIColor.lightText
		
		cell.titleLabel.attributedText = type * [NSForegroundColorAttributeName: color] + " [\(availability)]" * [NSForegroundColorAttributeName: UIColor.caption]
		cell.locationLabel.attributedText = location?.displayName ?? NSLocalizedString("Unknown", comment: "") * [:]
		
		switch contract.status {
		case .outstanding:
			let t = contract.dateExpired.timeIntervalSinceNow
			cell.stateLabel.attributedText = NSLocalizedString("Outstanding", comment: "") * [NSForegroundColorAttributeName: color] + " " + NCTimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes) * [NSForegroundColorAttributeName: UIColor.lightText]
		case .inProgress:
			let t = contract.dateExpired.timeIntervalSinceNow
			cell.stateLabel.attributedText = NSLocalizedString("In Progress", comment: "") * [NSForegroundColorAttributeName: color] + " " + NCTimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes) * [NSForegroundColorAttributeName: UIColor.lightText]
		case .cancelled:
			cell.stateLabel.attributedText = "\(NSLocalizedString("Cancelled", comment: "")) \(DateFormatter.localizedString(from: endDate, dateStyle: .medium, timeStyle: .medium))" * [NSForegroundColorAttributeName: UIColor.lightText]
		case .deleted:
			cell.stateLabel.attributedText = "\(NSLocalizedString("Deleted", comment: "")) \(DateFormatter.localizedString(from: endDate, dateStyle: .medium, timeStyle: .medium))" * [NSForegroundColorAttributeName: UIColor.lightText]
		case .failed:
			cell.stateLabel.attributedText = "\(NSLocalizedString("Failed", comment: "")) \(DateFormatter.localizedString(from: endDate, dateStyle: .medium, timeStyle: .medium))" * [NSForegroundColorAttributeName: UIColor.lightText]
		case .finished, .finishedContractor, .finishedIssuer:
			cell.stateLabel.attributedText = "\(NSLocalizedString("Finished", comment: "")) \(DateFormatter.localizedString(from: endDate, dateStyle: .medium, timeStyle: .medium))" * [NSForegroundColorAttributeName: UIColor.lightText]
		case .rejected:
			cell.stateLabel.attributedText = "\(NSLocalizedString("Rejected", comment: "")) \(DateFormatter.localizedString(from: endDate, dateStyle: .medium, timeStyle: .medium))" * [NSForegroundColorAttributeName: UIColor.lightText]
		case .reversed:
			cell.stateLabel.attributedText = "\(NSLocalizedString("Reversed", comment: "")) \(DateFormatter.localizedString(from: endDate, dateStyle: .medium, timeStyle: .medium))" * [NSForegroundColorAttributeName: UIColor.lightText]
		}
		
		if contract.issuerID == Int(characterID) {
			cell.dateLabel.text = DateFormatter.localizedString(from: contract.dateIssued, dateStyle: .medium, timeStyle: .medium)
		}
		else if let issuer = contacts?[Int64(contract.issuerID)]?.name {
			cell.dateLabel.text = "\(DateFormatter.localizedString(from: contract.dateIssued, dateStyle: .medium, timeStyle: .medium)) \(NSLocalizedString("by", comment: "")) \(issuer)"
		}
		
		/*cell.titleLabel.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		cell.subtitleLabel.attributedText = location?.displayName ?? NSLocalizedString("Unknown Location", comment: "") * [NSForegroundColorAttributeName: UIColor.lightText]
		cell.iconView.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		
		cell.priceLabel.text = NCUnitFormatter.localizedString(from: transaction.price, unit: .isk, style: .full)
		cell.qtyLabel.text = NCUnitFormatter.localizedString(from: Double(transaction.quantity), unit: .none, style: .full)
		cell.dateLabel.text = DateFormatter.localizedString(from: transaction.transactionDateTime, dateStyle: .medium, timeStyle: .medium)
		
		
		var s = "\(transaction.transactionType == .buy ? "-" : "")\(NCUnitFormatter.localizedString(from: transaction.price * Double(transaction.quantity), unit: .isk, style: .full))" * [NSForegroundColorAttributeName: transaction.transactionType == .buy ? UIColor.red : UIColor.green]
		if !transaction.clientName.isEmpty {
			s = s + " \(transaction.transactionType == .buy ? NSLocalizedString("to", comment: "") : NSLocalizedString("from", comment: "")) \(transaction.clientName)"
		}
		
		cell.amountLabel.attributedText = s*/
	}
	
	override var hashValue: Int {
		return contract.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCContractRow)?.hashValue == hashValue
	}
}

