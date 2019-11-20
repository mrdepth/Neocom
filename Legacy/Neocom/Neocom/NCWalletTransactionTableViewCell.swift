//
//  NCWalletTransactionTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

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

protocol NCWalletTransaction {
	var clientID: Int {get}
	var date: Date {get}
	var isBuy: Bool {get}
//	public var isPersonal: Bool
//	public var journalRefID: Int64
	var locationID: Int64 {get}
	var quantity: Int {get}
//	public var transactionID: Int64
	var typeID: Int {get}
	var unitPrice: Double {get}
	var hashValue: Int {get}
}

extension ESI.Wallet.Transaction: NCWalletTransaction {
}

extension ESI.Wallet.CorpTransaction: NCWalletTransaction {
}

class NCWalletTransactionRow: TreeRow {
	let transaction: NCWalletTransaction
	let location: NCLocation?
	let clientID: NSManagedObjectID?
	lazy var client: NCContact? = {
		guard let clientID = clientID else {return nil}
		return (try? NCCache.sharedCache?.viewContext.existingObject(with: clientID)) as? NCContact
	}()
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.transaction.typeID]
	}()
	
	init(transaction: NCWalletTransaction, location: NCLocation?, clientID: NSManagedObjectID?) {
		self.transaction = transaction
		self.location = location
		self.clientID = clientID
		
		super.init(prototype: Prototype.NCWalletTransactionTableViewCell.default, route: Router.Database.TypeInfo(transaction.typeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCWalletTransactionTableViewCell else {return}
		cell.titleLabel.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		cell.subtitleLabel.attributedText = location?.displayName ?? NSLocalizedString("Unknown Location", comment: "") * [NSAttributedStringKey.foregroundColor: UIColor.lightText]
		cell.iconView.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		
		cell.priceLabel.text = NCUnitFormatter.localizedString(from: transaction.unitPrice, unit: .isk, style: .full)
		cell.qtyLabel.text = NCUnitFormatter.localizedString(from: Double(transaction.quantity), unit: .none, style: .full)
		cell.dateLabel.text = DateFormatter.localizedString(from: transaction.date, dateStyle: .medium, timeStyle: .medium)
		
		
		var s = "\(transaction.isBuy ? "-" : "")\(NCUnitFormatter.localizedString(from: transaction.unitPrice * Double(transaction.quantity), unit: .isk, style: .full))" * [NSAttributedStringKey.foregroundColor: transaction.isBuy ? UIColor.red : UIColor.green]
		if let client = client?.name {
			s = s + " \(transaction.isBuy ? NSLocalizedString("to", comment: "") : NSLocalizedString("from", comment: "")) \(client)"
		}
		
		cell.amountLabel.attributedText = s
	}
	
	override lazy var hashValue: Int = transaction.hashValue
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCWalletTransactionRow)?.hashValue == hashValue
	}
}

