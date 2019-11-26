//
//  ESI+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/26/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

extension ESI {
    convenience init(token: OAuth2Token) {
        self.init(token: token, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey)
    }
}
