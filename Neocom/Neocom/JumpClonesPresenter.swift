//
//  JumpClonesPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/1/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class JumpClonesPresenter: TreePresenter {
	typealias View = JumpClonesViewController
	typealias Interactor = JumpClonesInteractor
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
								  Prototype.TreeDefaultCell.attribute,
								  Prototype.TreeDefaultCell.placeholder])

		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		var result = Presentation()
		
		let t = 3600 * 24 +  (content.value.clones.lastCloneJumpDate ?? .distantPast).timeIntervalSinceNow
		let s = String(format: NSLocalizedString("Clone jump availability: %@", comment: ""), t > 0 ? TimeIntervalFormatter.localizedString(from: t, precision: .minutes) : NSLocalizedString("Now", comment: ""))
		
		result.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														 title: NSLocalizedString("Next Clone Jump Availability", comment: "").uppercased(),
														 subtitle: s),
									diffIdentifier: "NextJump").asAnyItem)
		result.append(contentsOf:
			content.value.clones.jumpClones.enumerated().map { (i, clone) -> AnyTreeItem in
				let title = content.value.locations?[clone.locationID]?.displayName ?? NSAttributedString(string: NSLocalizedString("Unknown Location", comment: ""))
				return Tree.Item.ImplantsSection(clone.implants, attributedTitle: title.uppercased(), diffIdentifier: "Implants\(i)", treeController: view?.treeController).asAnyItem
		})

		return .init(result)
	}
}
