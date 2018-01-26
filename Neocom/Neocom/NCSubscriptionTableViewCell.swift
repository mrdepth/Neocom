//
//  NCSubscriptionTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.01.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import StoreKit
import ASReceipt

class NCSubscriptionTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var priceLabel: UILabel!
	@IBOutlet weak var periodLabel: UILabel!
}

extension Prototype {
	enum NCSubscriptionTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCSubscriptionTableViewCell", bundle: nil), reuseIdentifier: "NCSubscriptionTableViewCell")
	}
}

class NCSubscriptionRow: TreeRow {
	let product: SKProduct
	
	init(product: SKProduct, route: Route) {
		self.product = product
		super.init(prototype: Prototype.NCSubscriptionTableViewCell.default, route: route)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCSubscriptionTableViewCell else {return}
		cell.titleLabel.text = product.localizedTitle.uppercased()
		cell.subtitleLabel.text = product.localizedDescription
		
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.locale = product.priceLocale
		cell.priceLabel.text = formatter.string(from: product.price)
		cell.periodLabel.text = InAppProductID(rawValue: product.productIdentifier)?.period ?? ""
		cell.accessoryType = .none
	}
	
	override var hashValue: Int {
		return product.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCSubscriptionRow)?.hashValue == hashValue
	}
	
}

class NCSubscriptionStatusRow: TreeRow {
	let product: SKProduct
	let purchase: Receipt.Purchase
	init(product: SKProduct, purchase: Receipt.Purchase) {
		self.product = product
		self.purchase = purchase
		super.init(prototype: Prototype.NCSubscriptionTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCSubscriptionTableViewCell else {return}

		cell.titleLabel.text = product.localizedTitle.uppercased()
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.locale = product.priceLocale
		cell.priceLabel.text = formatter.string(from: product.price)
		cell.periodLabel.text = InAppProductID(rawValue: product.productIdentifier)?.period ?? ""

		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none
		cell.subtitleLabel.text = NSLocalizedString("ACTIVE. Renews", comment: "") + " " + dateFormatter.string(from: purchase.expiresDate!)
		cell.accessoryType = .checkmark
	}
	
	override var hashValue: Int {
		return purchase.transactionID.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCSubscriptionStatusRow)?.hashValue == hashValue
	}

}
