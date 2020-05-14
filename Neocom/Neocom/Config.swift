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
    
}

enum URLScheme {
    static let neocom = "nc"
    static let fitting = "fitting"
    static let showinfo = "showinfo"
}

extension Config {
    static let current = Config()
}
