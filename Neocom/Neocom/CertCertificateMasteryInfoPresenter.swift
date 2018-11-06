//
//  CertCertificateMasteryInfoPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/28/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class CertCertificateMasteryInfoPresenter: TreePresenter {
	typealias View = CertCertificateMasteryInfoViewController
	typealias Interactor = CertCertificateMasteryInfoInteractor
	typealias Presentation = [AnyTreeItem]
	
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
								  Prototype.TreeDefaultCell.default,
								  Prototype.CertCertificateDescriptionCell.default])
		
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
			let certificate: SDECertCertificate = try context.existingObject(with: input.objectID)!
			var sections = (certificate.masteries?.array as? [SDECertMastery])?.sorted {$0.level!.level < $1.level!.level}.compactMap { mastery -> AnyTreeItem? in
				let rows = (mastery.skills?.allObjects as? [SDECertSkill])?.sorted {$0.type!.typeName! < $1.type!.typeName!}.compactMap {
					Tree.Item.InvTypeRequiredSkillRow($0, character: character)
				}
				guard rows?.isEmpty == false else {return nil}
				
				let trainingQueue = TrainingQueue(character: character)
				trainingQueue.add(mastery)
				let title = NSLocalizedString("Level", comment: "").uppercased() + " \(String(romanNumber: Int(mastery.level!.level + 1)))"
				let section = Tree.Item.InvTypeSkillsSection(title: title,
															 trainingQueue: trainingQueue,
															 character: content.value,
															 diffIdentifier: mastery.objectID,
															 treeController: self?.view?.treeController,
															 isExpanded: trainingQueue.trainingTime() > 0,
															 children: rows,
															 action: { [weak self] control in
				})
				return section.asAnyItem
			} ?? []
			
			
			let image: UIImage?
			
			if content.value != nil {
				let level = (certificate.masteries?.array as? [SDECertMastery])?.sorted {$0.level!.level < $1.level!.level}.lazy.map { mastery -> (SDECertMastery, TimeInterval) in
					let tq = TrainingQueue(character: character)
					tq.add(mastery)
					return (mastery, tq.trainingTime())
					}.last {$1 == 0}?.0.level
				image = level?.icon?.image?.image ?? context.eveIcon(.mastery(nil))?.image?.image
			}
			else {
				image = context.eveIcon(.mastery(nil))?.image?.image
			}
			
			let description = Tree.Content.CertCertificateDescription(prototype: Prototype.CertCertificateDescriptionCell.default, title: certificate.certificateName ?? "", image: image, certDescription: certificate.certificateDescription?.text)

			let descriptionRow = Tree.Item.Row<Tree.Content.CertCertificateDescription>(description, diffIdentifier: "Description")
			sections.insert(descriptionRow.asAnyItem, at: 0)
			
			guard !sections.isEmpty else { throw NCError.noResults }
			return sections
		}
	}
	
}
