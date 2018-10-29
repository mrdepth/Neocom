//
//  SkillQueueInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 19/10/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class SkillQueueInteractor: TreeInteractor {
	typealias Presenter = SkillQueuePresenter
	typealias Content = ESI.Result<Character>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	private var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		return api.character(cachePolicy: cachePolicy)
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			self?.api = Services.api.current
			_ = self?.presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter?.view?.present(presentation, animated: true)
			}
		}
	}
	
	func addNewSkillPlan() {
		guard let account = Services.storage.viewContext.currentAccount else {return}
		account.skillPlans?.forEach {
			($0 as? SkillPlan)?.active = false
		}
		
		let skillPlan = SkillPlan(context: account.managedObjectContext!)
		skillPlan.name = NSLocalizedString("Unnamed", comment: "")
		skillPlan.account = account
		skillPlan.active = true
		try? Services.storage.viewContext.save()
	}
	
	func clear(_ skillPlan: SkillPlan) {
		(skillPlan.skills?.allObjects as? [SkillPlanSkill])?.forEach {
			$0.managedObjectContext?.delete($0)
		}
		
		try? Services.storage.viewContext.save()
	}
	
	func makeActive(_ skillPlan: SkillPlan) {
		skillPlan.account?.skillPlans?.forEach {
			($0 as? SkillPlan)?.active = false
		}
		skillPlan.active = true
		try? Services.storage.viewContext.save()
	}
	
	func rename(_ skillPlan: SkillPlan, with name: String) {
		if !name.isEmpty && skillPlan.name != name {
			skillPlan.name = name
			try? Services.storage.viewContext.save()
		}
	}
	
	func delete(_ skillPlan: SkillPlan) {
		if skillPlan.active {
			if let item = (skillPlan.account?.skillPlans?.sortedArray(using: [NSSortDescriptor(key: "name", ascending: true)]) as? [SkillPlan])?.first(where: { $0 !== skillPlan }) {
				item.active = true
			}
		}
		skillPlan.managedObjectContext?.delete(skillPlan)
		try? Services.storage.viewContext.save()
	}
	
	func delete(_ skill: SkillPlanSkill) {
		(skill.skillPlan?.skills?.allObjects as? [SkillPlanSkill])?.filter {
			$0.level >= skill.level && $0.typeID == skill.typeID
		}.forEach {
			$0.managedObjectContext?.delete($0)
		}
		try? Services.storage.viewContext.save()
	}
}
