//
//  InvTypeMarketOrdersPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/26/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures
import CloudData

class InvTypeMarketOrdersPresenter: TreePresenter {
	typealias View = InvTypeMarketOrdersViewController
	typealias Interactor = InvTypeMarketOrdersInteractor
	typealias Presentation = [Tree.Item.SimpleSection<Tree.Item.Row<Tree.Content.InvTypeMarketOrder>>]
	
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
								  Prototype.InvTypeMarketOrderCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
		
		let region = Services.sde.viewContext.mapRegion(interactor.regionID)
		view?.title = region?.regionName ?? NSLocalizedString("Market Orders", comment: "")

	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		
		
		let progress = Progress(totalUnitCount: 2)
		
		return DispatchQueue.global(qos: .utility).async { [weak self] () -> Presentation in
			guard let strongSelf = self else { throw NCError.cancelled(type: type(of: self), function: #function) }

			var orders = content.value
			guard !orders.isEmpty else { throw NCError.noResults }

			let locationIDs = Set(orders.map{$0.locationID})
			let locations = progress.performAsCurrent(withPendingUnitCount: 1) { try? strongSelf.interactor.locations(ids: locationIDs).get() }
			


			
			let i = orders.partition { $0.isBuyOrder }
			var sell = orders[..<i]
			var buy = orders[i...]

			buy.sort {return $0.price > $1.price}
			sell.sort {return $0.price < $1.price}

			let sellRows = sell.map { Tree.Item.Row(Tree.Content.InvTypeMarketOrder(prototype: Prototype.InvTypeMarketOrderCell.default, order: $0, location: locations?[$0.locationID]?.displayName)) }
			let buyRows = buy.map { Tree.Item.Row(Tree.Content.InvTypeMarketOrder(prototype: Prototype.InvTypeMarketOrderCell.default, order: $0, location: locations?[$0.locationID]?.displayName)) }
			
			progress.completedUnitCount += 1

			return [Tree.Item.SimpleSection(title: NSLocalizedString("Sellers", comment: "").uppercased(), treeController: strongSelf.view?.treeController, children: sellRows),
					Tree.Item.SimpleSection(title: NSLocalizedString("Buyers", comment: "").uppercased(), treeController: strongSelf.view?.treeController, children: buyRows)]
		}
	}
	
	func onRegions(_ sender: Any) {
		guard let view = view else {return}
		Router.SDE.mapLocationPicker(MapLocationPicker.View.Input(mode: [.regions], completion: { [weak self] (controller, location) in
			if case let .region(region) = location {
				UserDefaults.standard.set(region.regionID, forKey: UserDefaults.Key.marketRegion)
				self?.view?.title = region.regionName ?? NSLocalizedString("Market Orders", comment: "")
				self?.reloadIfNeeded()
			}

			guard let view = self?.view else {return}
			controller.unwinder?.unwind(to: view)
			
		})).perform(from: view)
	}
}
