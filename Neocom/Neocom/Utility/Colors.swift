//
//  Colors.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import SwiftUI


extension Color {
    static var skyBlue: Color {
        return Color("skyBlue")
    }
    
    static var emDamage: Color {
        return Color("emDamage")
    }

    static var explosiveDamage: Color {
        return Color("explosiveDamage")
    }

    static var kineticDamage: Color {
        return Color("kineticDamage")
    }

    static var thermalDamage: Color {
        return Color("thermalDamage")
    }
    
    static func security(_ security: Float) -> Color {
        if security >= 1.0 {
            return Color("security1.0")
        }
        else if security >= 0.9 {
            return Color("security0.9")
        }
        else if security >= 0.8 {
            return Color("security0.8")
        }
        else if security >= 0.7 {
            return Color("security0.7")
        }
        else if security >= 0.6 {
            return Color("security0.6")
        }
        else if security >= 0.5 {
            return Color("security0.5")
        }
        else if security >= 0.4 {
            return Color("security0.4")
        }
        else if security >= 0.3 {
            return Color("security0.3")
        }
        else if security >= 0.2 {
            return Color("security0.2")
        }
        else if security >= 0.1 {
            return Color("security0.1")
        }
        else {
            return Color("security0.0")
        }
    }
}

extension UIColor {
    static var descriptionLabel: UIColor {
        UIColor(named: "descriptionLabel")!
    }
}
