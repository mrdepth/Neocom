//
//  FleetDescription.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/22/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation

@objc(FleetDescription)
public class FleetDescription: NSObject, NSSecureCoding {
    public var pilots: [Int: String]?
    public var links: [Int: Int]?
    
    public enum CodingKeys: String, CodingKey {
        case pilots
        case links
    }

    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public override init() {
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        var dic = aDecoder.decodeObject(of: [NSDictionary.self, NSString.self, NSNumber.self], forKey: CodingKeys.pilots.stringValue)
        if let dic = dic as? [String: String] {
            pilots = Dictionary(dic.map {(Int($0) ?? $0.hashValue, $1)},
                                uniquingKeysWith: { a, _ in a })
        }
        else {
            pilots = dic as? [Int: String]
        }
        
        dic = aDecoder.decodeObject(of: [NSDictionary.self, NSString.self, NSNumber.self], forKey: CodingKeys.links.stringValue)

        if let dic = dic as? [String: String] {
            links = Dictionary(dic.map {(Int($0) ?? $0.hashValue, Int($1) ?? $1.hashValue)},
                                uniquingKeysWith: { a, _ in a })
        }
        else {
            links = dic as? [Int: Int]
        }

    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(pilots, forKey: CodingKeys.pilots.stringValue)
        aCoder.encode(links, forKey: CodingKeys.links.stringValue)
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? FleetDescription else {return false}
        return pilots == other.pilots &&
            links == other.links
    }

}
