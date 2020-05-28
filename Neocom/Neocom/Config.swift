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
//	var urlScheme = "nc"
    var supportEmail = "support@eveuniverseiphone.com"
    let homepage = URL(string: "https://facebook.com/groups/Neocom")!
    let sources = URL(string: "https://github.com/mrdepth/Neocom")!
    let terms = URL(string: "https://mrdepth.github.io/Neocom/terms.html")!
    let privacy = URL(string: "https://mrdepth.github.io/Neocom/privacy.html")!

    let loadoutPathExtension = "loadout"
    
    struct InApps {
        var autoRenewableSubscriptions = ["com.shimanski.neocom.removeads.month",
                                          "com.shimanski.neocom.removeads.months6",
                                          "com.shimanski.neocom.removeads.year"]
        var lifetimeSubscriptions = ["com.shimanski.neocom.removeads.lifetime1"]
        var donate = ["com.shimanski.neocom.donate.tier1",
                      "com.shimanski.neocom.donate.tier5",
                      "com.shimanski.neocom.donate.tier10",
                      "com.shimanski.neocom.donate.tier50"]
        var allProducts: [String] {
            autoRenewableSubscriptions + lifetimeSubscriptions + donate
        }
    }
    
    let inApps = InApps()
    let appodealKey = "94f0ed36388a0a458bdf528df128c4427c4d4fb50130f981"
}

enum URLScheme {
    static let neocom = "nc"
    static let fitting = "fitting"
    static let showinfo = "showinfo"
}

extension Config {
    static let current = Config()
}
