//
//  Constants.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

enum NCDBAttributeID: Int {
	case None = 0
	case CharismaBonus = 175
	case IntelligenceBonus = 176
	case MemoryBonus = 177
	case PerceptionBonus = 178
	case WillpowerBonus = 179
	case PrimaryAttribute = 180
	case SecondaryAttribute = 181
	case SkillTimeConstant = 275
	
	case Charisma = 164
	case Intelligence = 165
	case Memory = 166
	case Perception = 167
	case Willpower = 168
}

extension NSNotification.Name {
	public static let NCCurrentAccountChanged = "NCCurrentAccountChanged" 
}
