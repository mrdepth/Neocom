//
//  UnitFormatter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation

class UnitFormatter: Formatter {
    
    lazy var numberFormatter: NumberFormatter =  {
        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.groupingSize = 3
        numberFormatter.groupingSeparator = " "
        numberFormatter.decimalSeparator = "."
        return numberFormatter
    }()
    
    var unit: Unit = .none
    var style: Style = .long
    
    init(unit: Unit = .none, style: Style = .long) {
        self.unit = unit
        self.style = style
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func string(from value: Double) -> String {
        let scale: Scale
        switch style {
        case .long:
            scale = .natural
        case .short:
            switch value / 10 {
            case Scale.tera.divider...:
                scale = .tera
            case Scale.giga.divider..<Scale.tera.divider:
                scale = .giga
            case Scale.mega.divider..<Scale.giga.divider:
                scale = .mega
            case Scale.kilo.divider..<Scale.mega.divider:
                scale = .kilo
            default:
                scale = .natural
            }
        }
        
        let value = value / scale.divider
        
        switch fabs(value) {
        case ..<10:
            numberFormatter.maximumFractionDigits = 2
        case 10..<100:
            numberFormatter.maximumFractionDigits = 1
        default:
            numberFormatter.maximumFractionDigits = 0
        }
        
        
        return (numberFormatter.string(from: NSNumber(value: value)) ?? "") + unit.suffix(scale: scale)
    }
    
    override func string(for obj: Any?) -> String? {
        guard let value = obj as? Double else {return nil}
        return string(from: value)
    }
    
    class func localizedString<T: BinaryFloatingPoint>(from value: T, unit: Unit, style: Style) -> String {
        let formatter = UnitFormatter(unit: unit, style: style)
        return formatter.string(from: Double(value))
    }
    
    class func localizedString<T: BinaryInteger>(from value: T, unit: Unit, style: Style) -> String {
        localizedString(from: Double(value), unit: unit, style: style)
    }
    
    class func localizedString<T: BinaryFloatingPoint>(from range: ClosedRange<T>, unit: Unit, style: Style) -> String {
        let formatter = UnitFormatter(unit: .none, style: style)
        let a = formatter.string(from: Double(range.lowerBound))
        formatter.unit = unit
        let b = formatter.string(from: Double(range.upperBound))
        return "\(a)/\(b)"
    }
    
    class func localizedString<T: BinaryInteger>(from range: ClosedRange<T>, unit: Unit, style: Style) -> String {
        localizedString(from: Double(range.lowerBound)...Double(range.upperBound), unit: unit, style: style)
    }

}

extension UnitFormatter {
    enum Style {
        case short
        case long
    }
    
    
    enum Scale {
        case natural
        case kilo
        case mega
        case giga
        case tera
        
        var divider: Double {
            switch self {
            case .natural:
                return 1.0
            case .kilo:
                return 1E3
            case .mega:
                return 1E6
            case .giga:
                return 1E9
            case .tera:
                return 1E12
            }
        }
    }
    
    enum Unit {
        case none
        case isk
        case loyaltyPoints
        case skillPoints
        case gigaJoule
        case gigaJoulePerSecond
        case megaWatts
        case teraflops
        case kilogram
        case meter
        case millimeter
        case megaBitsPerSecond
        case cubicMeter
        case meterPerSecond
        case auPerSecond
        case hpPerSecond
        case skillPointsPerSecond
        case seconds
        
        var symbol: String {
            switch (self) {
            case .none:
                return ""
            case .isk:
                return NSLocalizedString("ISK", comment: "isk")
            case .loyaltyPoints:
                return NSLocalizedString("LP", comment: "loyaltyPoints")
            case .skillPoints:
                return NSLocalizedString("SP", comment: "skillPoints")
            case .gigaJoule:
                return NSLocalizedString("GJ", comment: "gigaJoule")
            case .gigaJoulePerSecond:
                return NSLocalizedString("GJ/s", comment: "gigaJoulePerSecond")
            case .megaWatts:
                return NSLocalizedString("MW", comment: "megaWatts")
            case .teraflops:
                return NSLocalizedString("Tf", comment: "teraflops")
            case .kilogram:
                return NSLocalizedString("kg", comment: "kilogram")
            case .meter:
                return NSLocalizedString("m", comment: "meter")
            case .millimeter:
                return NSLocalizedString("mm", comment: "millimeter")
            case .megaBitsPerSecond:
                return NSLocalizedString("Mbit/s", comment: "megaBitsPerSecond")
            case .cubicMeter:
                return NSLocalizedString("m³", comment: "cubicMeter")
            case .meterPerSecond:
                return NSLocalizedString("m/s", comment: "meterPerSecond")
            case .auPerSecond:
                return NSLocalizedString("AU/s", comment: "auPerSecond")
            case .hpPerSecond:
                return NSLocalizedString("HP/s", comment: "hpPerSecond")
            case .skillPointsPerSecond:
                return NSLocalizedString("SP/s", comment: "spPerSecond")
            case .seconds:
                return NSLocalizedString("s", comment: "seconds")
            }
        }
        
        func suffix(scale: Scale) -> String {
            
            switch self {
            case .none:
                switch scale {
                case .natural:
                    return ""
                case .kilo:
                    return NSLocalizedString("k", comment: "kilo SI prefix")
                case .mega:
                    return NSLocalizedString("M", comment: "mega SI prefix")
                case .giga:
                    return NSLocalizedString("B", comment: "billions prefix")
                case .tera:
                    return NSLocalizedString("T", comment: "tera SI prefix")
                }
            case .seconds:
                switch scale {
                case .natural:
                    return "\(symbol)"
                case .kilo:
                    return "\(NSLocalizedString("k", comment: "kilo SI prefix")) \(symbol)"
                case .mega:
                    return "\(NSLocalizedString("M", comment: "mega SI prefix")) \(symbol)"
                case .giga:
                    return "\(NSLocalizedString("B", comment: "billions prefix")) \(symbol)"
                case .tera:
                    return "\(NSLocalizedString("T", comment: "tera SI prefix")) \(symbol)"
                }
            case .skillPoints, .gigaJoule, .gigaJoulePerSecond, .megaWatts, .teraflops, .kilogram, .millimeter, .megaBitsPerSecond, .cubicMeter, .auPerSecond, .hpPerSecond, .skillPointsPerSecond, .isk, .loyaltyPoints:
                switch scale {
                case .natural:
                    return " \(symbol)"
                case .kilo:
                    return "\(NSLocalizedString("k", comment: "kilo SI prefix")) \(symbol)"
                case .mega:
                    return "\(NSLocalizedString("M", comment: "mega SI prefix")) \(symbol)"
                case .giga:
                    return "\(NSLocalizedString("B", comment: "billions prefix")) \(symbol)"
                case .tera:
                    return "\(NSLocalizedString("T", comment: "tera SI prefix")) \(symbol)"
                }
            case .meter, .meterPerSecond:
                switch scale {
                case .natural:
                    return " \(symbol)"
                case .kilo:
                    return " \(NSLocalizedString("k", comment: "kilo SI prefix"))\(symbol)"
                case .mega:
                    return " \(NSLocalizedString("M", comment: "mega SI prefix"))\(symbol)"
                case .giga:
                    return " \(NSLocalizedString("G", comment: "giga SI prefix"))\(symbol)"
                case .tera:
                    return " \(NSLocalizedString("T", comment: "tera SI prefix"))\(symbol)"
                }
            }
        }
    }
    
}
