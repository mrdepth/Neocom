//
//  MySkillsPagePresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/31/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class MySkillsPagePresenter: TreePresenter {
	typealias View = MySkillsPageViewController
	typealias Interactor = MySkillsPageInteractor
	typealias Presentation = [Tree.Item.Section<Tree.Content.Section, Tree.Item.SkillRow>]
	
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
								  Prototype.SkillCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		
		let sections = content.map { section -> Tree.Item.Section<Tree.Content.Section, Tree.Item.SkillRow> in
			let title = " \(section.groupName) (\(UnitFormatter.localizedString(from: section.rows.count, unit: .none, style: .long)) \(NSLocalizedString("SKILLS", comment: "")), \(UnitFormatter.localizedString(from: section.skillPoints, unit: .skillPoints, style: .long))) "
			return Tree.Item.Section(Tree.Content.Section(title: title), isExpanded: false, diffIdentifier: section.groupName, expandIdentifier: section.groupName, treeController: view?.treeController, children: section.rows)
		}
		return .init(sections)
	}
}
