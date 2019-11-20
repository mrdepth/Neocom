//
//  Character_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 21.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import Neocom

class Character_Tests: TestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSkill() {
		let context = Services.sde.viewContext
		let skill = Character.Skill(type: context.invType("Navigation")!)!
		
		for (level, sp) in zip([1,2,3,4,5], [250, 1415, 8000, 45255, 256000]) {
			XCTAssertEqual(skill.skillPoints(at: level), sp)
			XCTAssertEqual(skill.level(with: sp), level)
			XCTAssertEqual(skill.level(with: sp - 1), level - 1)
			XCTAssertEqual(skill.level(with: sp + 1), level)
		}

		let attributes = Character.Attributes(intelligence: 25, memory: 20, perception: 15, willpower: 20, charisma: 19)
		XCTAssertEqual(skill.skillPointsPerSecond(with: attributes), ((25 + 15 / 2.0) / 60.0), accuracy: 0.001)
    }
	
	func testTrainingQueue() {
		let context = Services.sde.viewContext
		let character = Character(attributes: .default, augmentations: .none, trainedSkills: [:], skillQueue: [])
		let trainingQueue = TrainingQueue(character: character)
		
		let t0 = trainingQueue.trainingTime()
		trainingQueue.add(context.invType("Navigation")!, level: 5)
		let t1 = trainingQueue.trainingTime()
		trainingQueue.add(context.invType("Gallente Cruiser")!, level: 3)
		let t2 = trainingQueue.trainingTime()
		trainingQueue.add(context.invType("Gallente Cruiser")!, level: 5)
		let t3 = trainingQueue.trainingTime()
		XCTAssertEqual(t0, 0)
		XCTAssertGreaterThan(t1, t0)
		XCTAssertGreaterThan(t2, t1)
		XCTAssertGreaterThan(t3, t2)
	}
    
}
