//
//  WidgetData.swift
//  Neocom
//
//  Created by Artem Shimanski on 12.01.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

struct WidgetData: Codable {
	static var url: URL? {
		return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.shimanski.neocom")?.appendingPathComponent("data.json")
	}
	
	struct Account: Codable {
		struct SkillQueueItem: Codable {
			let skillName: String
			let startDate: Date
			let finishDate: Date
			let level: Int
			let rank: Float
			let startSP: Int?
			let endSP: Int?
		}
		let characterID: Int64
		let characterName: String
		let uuid: String
		let skillQueue: [SkillQueueItem]
	}
	let accounts: [Account]
}


extension WidgetData.Account.SkillQueueItem {
	
	func skillPoints(at level: Int) -> Int {
		if (level == 0 || rank == 0) {
			return 0
		}
		let sp = pow(2, 2.5 * Double(level) - 2.5) * 250.0 * Double(rank)
		return Int(ceil(sp))
	}
	
	var skillPoints: Int {
		if let startSP = startSP,
			finishDate > Date() {
			let endSP = skillPoints(at: level + 1)
			let t = finishDate.timeIntervalSince(startDate)
			if t > 0 {
				let spps = Double(endSP - startSP) / t
				let t = finishDate.timeIntervalSinceNow
				let sp = Int(t > 0 ? Double(endSP) - t * spps : Double(endSP))
				return max(sp, startSP);
			}
			else {
				return endSP
			}
		}
		else {
			return skillPoints(at: level)
		}
	}
	
	var trainingProgress: Float {
		let start = Double(skillPoints(at: level))
		let end = Double(skillPoints(at: level + 1))
		let sp = Double(skillPoints)
		let progress = (sp - start) / (end - start);
		return Float(progress)
	}

}
