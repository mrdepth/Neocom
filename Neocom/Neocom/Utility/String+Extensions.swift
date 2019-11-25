//
//  String+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation

extension String {
    private static let roman = ["0","I","II","III","IV","V"]

    init(roman number: Int) {
        if String.roman.indices.contains(number) {
            self = String.roman[number]
        }
        else {
            self = "\(number)"
        }
    }
}
