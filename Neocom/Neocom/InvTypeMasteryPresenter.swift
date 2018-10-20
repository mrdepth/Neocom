//
//  InvTypeMasteryPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 17/10/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class InvTypeMasteryPresenter: TreePresenter {
	typealias View = InvTypeMasteryViewController
	typealias Interactor = InvTypeMasteryInteractor
	typealias Presentation = [Tree.Item.InvTypeSkillsSection]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeHeaderCell.default,
								  Prototype.TreeDefaultCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let input = view?.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		let character = content.value ?? .empty
		
		return Services.sde.performBackgroundTask { [weak self] context -> Presentation in
			let type: SDEInvType = try context.existingObject(with: input.typeObjectID)!
			let level: SDECertMasteryLevel = try context.existingObject(with: input.masteryLevelObjectID)!

			let masteries = try context.managedObjectContext
				.from(SDECertMastery.self)
				.filter(\SDECertMastery.level == level && (\SDECertMastery.certificate?.types).contains(type))
				.sort(by: \SDECertMastery.certificate?.certificateName, ascending: true)
				.all()
			
			let sections = masteries.compactMap { mastery -> Tree.Item.InvTypeSkillsSection? in
				let rows = (mastery.skills?.allObjects as? [SDECertSkill])?.sorted {$0.type!.typeName! < $1.type!.typeName!}.compactMap {
					Tree.Item.InvTypeRequiredSkillRow($0, character: character)
				}
				guard rows?.isEmpty == false else {return nil}
				
				let trainingQueue = TrainingQueue(character: character)
				trainingQueue.add(mastery)
				let title = mastery.certificate?.certificateName?.uppercased() ?? ""
				let section = Tree.Item.InvTypeSkillsSection(title: title, trainingQueue: trainingQueue, character: content.value, diffIdentifier: mastery.objectID, treeController: self?.view?.treeController, isExpanded: trainingQueue.trainingTime() > 0, children: rows)
				return section
			}
			
			guard !sections.isEmpty else {throw NCError.noResults}
			return sections

		}
	}
}
