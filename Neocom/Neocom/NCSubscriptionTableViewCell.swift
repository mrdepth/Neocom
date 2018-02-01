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
	let inApp: InAppProductID
	
	init(product: SKProduct, inApp: InAppProductID, route: Route) {
		self.product = product
		self.inApp = inApp
		super.init(prototype: Prototype.NCSubscriptionTableViewCell.default, route: route)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCSubscriptionTableViewCell else {return}
		cell.titleLabel.text = product.localizedTitle.uppercased()
//		cell.subtitleLabel.text = product.localizedDescription
		
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.locale = product.priceLocale
		cell.priceLabel.text = formatter.string(from: product.price)
		cell.periodLabel.text = InAppProductID(rawValue: product.productIdentifier)?.localizedPeriod.uppercased() ?? ""
		
		let period = inApp.periodInMonths
		if period > 1 {
			let price = product.price.doubleValue / Double(period)
			cell.subtitleLabel.text = String(format: NSLocalizedString("or %@ per month", comment: ""), formatter.string(from: price as NSNumber) ?? "")
		}
		else {
			cell.subtitleLabel.text = ""
		}
		
		cell.accessoryType = .none
	}
	
}

class NCSubscriptionStatusRow: TreeRow {
	let product: SKProduct
	let purchase: Receipt.Purchase
	let inApp: InAppProductID
	
	init(product: SKProduct, inApp: InAppProductID, purchase: Receipt.Purchase) {
		self.product = product
		self.inApp = inApp
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
		cell.periodLabel.text = InAppProductID(rawValue: product.productIdentifier)?.localizedPeriod.uppercased() ?? ""
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none
//		dateFormatter.timeStyle = .medium
		let subtitle = NSLocalizedString("ACTIVE. Renews on", comment: "") + " " + dateFormatter.string(from: purchase.expiresDate!)
		cell.subtitleLabel.text = subtitle
		cell.accessoryType = .checkmark
	}
	
}
