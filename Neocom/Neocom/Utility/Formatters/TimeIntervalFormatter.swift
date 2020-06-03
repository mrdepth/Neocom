//
//  TimeIntervalFormatter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation

class TimeIntervalFormatter: Formatter {
    enum Precision: Int {
        case seconds
        case minutes
        case hours
        case days
    };
    
    enum Format {
        case `default`
        case colonSeparated
    }
    
    var precision: Precision = .seconds
    var format: Format = .default
    
    class func localizedString(from timeInterval: TimeInterval, precision: Precision, format: Format = .default) -> String {
        let t = UInt(timeInterval.clamped(to: 0...Double(Int.max)))
        let d = t / (60 * 60 * 24);
        let h = (t / (60 * 60)) % 24;
        let m = (t / 60) % 60;
        let s = t % 60;
        
        if format == .colonSeparated {
            switch precision {
            case .days:
                return String(format: "%.2d:%.2d:%.2d:%.2d", d, h, m, s)
            case .hours:
                return String(format: "%.2d:%.2d:%.2d", h, m, s)
            case .minutes:
                return String(format: "%.2d:%.2d", m, s)
            case .seconds:
                return String(format: "%.2d", m, s)
            }
        }
        else {
            var string = ""
            var empty = true
            
            if (precision.rawValue <= Precision.days.rawValue && d > 0) {
                string += "\(d)\(NSLocalizedString("d", comment: "days"))"
                empty = false
            }
            if (precision.rawValue <= Precision.hours.rawValue && h > 0) {
                string += "\(empty ? "" : " ")\(h)\(NSLocalizedString("h", comment: "hours"))"
                empty = false
            }
            if (precision.rawValue <= Precision.minutes.rawValue && m > 0) {
                string += "\(empty ? "" : " ")\(m)\(NSLocalizedString("m", comment: "minutes"))"
                empty = false
            }
            if (precision.rawValue <= Precision.seconds.rawValue && s > 0) {
                string += "\(empty ? "" : " ")\(s)\(NSLocalizedString("s", comment: "seconds"))"
                empty = false
            }
            return empty ? "0\(NSLocalizedString("s", comment: "seconds"))" : string;
        }
    }
    
    override func string(for obj: Any?) -> String? {
        guard let obj = obj as? TimeInterval else {return nil}
        return TimeIntervalFormatter.localizedString(from: obj, precision: precision)
    }
    
}
