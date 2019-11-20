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

class Skills_Tests: TestCase {

    override func setUp() {
		super.setUp()
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
