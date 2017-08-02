//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

public enum Filter {
	case characterID([Int64])
	case corporationID([Int64])
	case allianceID([Int64])
	case factionID([Int64])
	case shipTypeID([Int])
	case groupID([Int])
	case solarSystemID([Int])
	case regionID([Int])
	case warID([Int])
	case iskValue(Int64)
	case startTime(Date)
	case endTime(Date)
	case noItems
	case noAttackers
	case zkbOnly
	case kills
	case losses
	case wSpace
	case solo
	case finalBlowOnly
	
}


var f: [Filter] = [.characterID([1]), .corporationID([2])]



for case let .characterID(ids) in f {
	
}
