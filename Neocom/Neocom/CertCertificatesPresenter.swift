//
//  CertCertificatesPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/28/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import CoreData
import Expressible

class CertCertificatesPresenter: TreePresenter {
    typealias View = CertCertificatesViewController
    typealias Interactor = CertCertificatesInteractor
    typealias Presentation = Tree.Item.CertificatesFetchedResultsController
    
    weak var view: View?
    lazy var interactor: Interactor! = Interactor(presenter: self)
    
    var content: Interactor.Content?
    var presentation: Presentation?
    var loading: Future<Presentation>?
    
    required init(view: View) {
        self.view = view
    }
    
    func configure() {
        view?.tableView.register([Prototype.TreeDefaultCell.default])
        
        interactor.configure()
        applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
            self?.applicationWillEnterForeground()
        }
		view?.title = view?.input?.groupName
    }
    
    private var applicationWillEnterForegroundObserver: NotificationObserver?
    
    func presentation(for content: Interactor.Content) -> Future<Presentation> {
        guard let input = view?.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		let controller = Services.sde.viewContext.managedObjectContext
			.from(SDECertCertificate.self)
			.filter(\SDECertCertificate.group == input)
			.sort(by: \SDECertCertificate.certificateName, ascending: true)
			.fetchedResultsController()
		
        return .init(Presentation(controller, treeController: view?.treeController, character: content.value))
    }
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.CertCertificateRow, let view = view else {return}
		Router.SDE.certCertificateInfo(item.result).perform(from: view)
	}

}

extension Tree.Item {
	class CertificatesFetchedResultsController: FetchedResultsController<FetchedResultsSection<CertCertificateRow>> {
		var character: Character?
		init(_ fetchedResultsController: NSFetchedResultsController<Section.Child.Result>, treeController: TreeController?, character: Character?) {
			self.character = character
			super.init(fetchedResultsController, diffIdentifier: fetchedResultsController.fetchRequest, treeController: treeController)
		}
	}
	
	class CertCertificateRow: FetchedResultsRow<SDECertCertificate> {
		private var subtitle: String?
		private var image: UIImage?
		
		override var prototype: Prototype? {
			return Prototype.TreeDefaultCell.default
		}
		
		override func configure(cell: UITableViewCell) {
			guard let cell = cell as? TreeDefaultCell else {return}
			if let character = (section?.controller as? CertificatesFetchedResultsController)?.character, subtitle == nil {
				
				Services.sde.performBackgroundTask { context in
					let certificate: SDECertCertificate = try! context.existingObject(with: self.result.objectID)!
					let result = (certificate.masteries?.array as? [SDECertMastery])?.sorted {$0.level!.level < $1.level!.level}.lazy.map { mastery -> (SDECertMastery, TimeInterval) in
						let tq = TrainingQueue(character: character)
						tq.add(mastery)
						return (mastery, tq.trainingTime())
					}.first {$1 > 0}
					
					let subtitle: String
					let image: UIImage?
					
					if let result = result {
						subtitle = String.localizedStringWithFormat(NSLocalizedString("%@ to level %d", comment: ""),
																	TimeIntervalFormatter.localizedString(from: result.1, precision: .seconds),
																	result.0.level!.level + 2)
						image = context.eveIcon(.mastery(Int(result.0.level!.level - 1)))?.image?.image
					}
					else {
						subtitle = ""
						image = context.eveIcon(.mastery(4))?.image?.image
					}
					
					DispatchQueue.main.async {
						self.subtitle = subtitle
						self.image = image
						self.section?.controller?.treeController?.reloadRow(for: self, with: .fade)
					}
				}
			}
			
			cell.titleLabel?.text = result.certificateName
			cell.subtitleLabel?.text = subtitle
			cell.iconView?.image = image ?? Services.sde.viewContext.eveIcon(.mastery(nil))?.image?.image
			cell.accessoryType = .disclosureIndicator
		}
	}
}
