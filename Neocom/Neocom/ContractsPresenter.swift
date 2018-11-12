//
//  ContractsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class ContractsPresenter: TreePresenter {
	typealias View = ContractsViewController
	typealias Interactor = ContractsInteractor
	typealias Presentation = [Tree.Item.RoutableRow<Tree.Content.Contract>]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.ContractCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let characterID = Services.storage.viewContext.currentAccount?.characterID else {return .init(.failure(NCError.authenticationRequired))}
		
		var contracts = content.value.contracts.map { contract -> Tree.Content.Contract in
			let endDate: Date = contract.dateCompleted ?? {
				guard let date = contract.dateAccepted, let duration = contract.daysToComplete else {return nil}
				return date.addingTimeInterval(TimeInterval(duration) * 24 * 3600)
				}() ?? contract.dateExpired

			return Tree.Content.Contract(prototype: Prototype.ContractCell.default,
								  contract: contract,
								  issuer: content.value.contacts?[Int64(contract.issuerID)],
								  location: (contract.startLocationID).flatMap{content.value.locations?[$0]} ?? EVELocation.unknown,
								  endDate: endDate,
								  characterID: characterID)
		}
		
		let i = contracts.partition{$0.contract.isOpen}
		let open = contracts[i...]
		let closed = contracts[..<i]
		
		let rows = open.sorted {$0.contract.dateExpired < $1.contract.dateExpired} +
			closed.sorted{$0.endDate > $1.endDate}
		return .init(rows.map { Tree.Item.RoutableRow($0, route: Router.Business.contractInfo($0.contract)) })
	}
}
