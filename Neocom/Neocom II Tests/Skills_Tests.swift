//
//  Skills_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 10/26/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import Neocom
import EVEAPI
import Futures

class Skills_Tests: XCTestCase {

    override func setUp() {
		Services.cache = cache
		Services.sde = sde
		Services.storage = storage
		
		if storage.viewContext.account(with: oAuth2Token) == nil {
			_ = storage.viewContext.newAccount(with: oAuth2Token)
			try! storage.viewContext.save()
		}
		if storage.viewContext.currentAccount == nil {
			storage.viewContext.setCurrentAccount(storage.viewContext.accounts.first)
		}
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSkillQueue() {
		let exp = expectation(description: "end")
		let skillPlan = Services.storage.viewContext.currentAccount?.activeSkillPlan
		
		let controller = try! SkillQueue.default.instantiate().get()
		controller.loadViewIfNeeded()
		controller.presenter.interactor = SkillQueueInteractorMock(presenter: controller.presenter)
		controller.viewWillAppear(true)
		controller.viewDidAppear(true)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
			let type = Services.sde.viewContext.invType("Navigation")!
			let tq = TrainingQueue(character: controller.presenter.content!.value)
			tq.add(type, level: 1)
			skillPlan?.add(tq)
			try! Services.storage.viewContext.save()
		
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
				exp.fulfill()
			}
		}
		
		wait(for: [exp], timeout: 10)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

class SkillQueueInteractorMock: SkillQueueInteractor {
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<SkillQueueInteractor.Content> {
		var character = Neocom.Character.empty
		let skill = Neocom.Character.Skill(type: Services.sde.viewContext.invType("Navigation")!)!
		
		let queuedSkill = ESI.Skills.SkillQueueItem.init(finishDate: Date.init(timeIntervalSinceNow: 60), finishedLevel: 1, levelEndSP: skill.skillPoints(at: 1), levelStartSP: 0, queuePosition: 0, skillID: skill.typeID, startDate: Date.init(timeIntervalSinceNow: -60), trainingStartSP: 0)
		character.skillQueue.append(Neocom.Character.SkillQueueItem(skill: skill, queuedSkill: queuedSkill))
		let result = ESI.Result(value: character, expires: nil, metadata: nil)
		return .init(result)
	}
}
