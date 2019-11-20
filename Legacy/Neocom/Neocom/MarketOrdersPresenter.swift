//
//  MarketOrdersPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/9/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class MarketOrdersPresenter: TreePresenter {
	typealias View = MarketOrdersViewController
	typealias Interactor = MarketOrdersInteractor
	typealias Presentation = [Tree.Item.SimpleSection<Tree.Item.MarketOrderRow>]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeSectionCell.default,
								  Prototype.MarketOrderCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		
		let buy = content.value.orders
			.filter{$0.isBuyOrder == true}
			.map {Tree.Item.MarketOrderRow($0, location: content.value.locations?[$0.locationID])}
			.sorted{$0.expired < $1.expired}
		let sell = content.value.orders
			.filter{$0.isBuyOrder != true}
			.map {Tree.Item.MarketOrderRow($0, location: content.value.locations?[$0.locationID])}
			.sorted{$0.expired < $1.expired}
		
		var result = Presentation()

		if !sell.isEmpty {
			result.append(Tree.Item.SimpleSection(title: NSLocalizedString("Sell", comment: "").uppercased(), treeController: view?.treeController, children: sell))
		}
		if !buy.isEmpty {
			result.append(Tree.Item.SimpleSection(title: NSLocalizedString("Buy", comment: "").uppercased(), treeController: view?.treeController, children: buy))
		}

		return .init(result)
	}
}
