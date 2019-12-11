//
//  Config.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/26/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation

let bundleID = Bundle.main.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as! String

struct Config {
    struct ESI {
        var clientID = "a0cc80b7006944249313dc22205ec645"
        var secretKey = "deUqMep7TONp68beUoC1c71oabAdKQOJdbiKpPcC"
        var callbackURL = URL(string: "eveauthnc://sso/")!
    }
    var esi = ESI()
}


extension Config {
    static let current = Config()
}
