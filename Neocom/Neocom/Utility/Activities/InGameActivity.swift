//
//  InGameActivity.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/8/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine
import EVEAPI

class InGameActivity: UIActivity {
    var esi: ESI
    var characterID: Int64
    
    init(esi: ESI, characterID: Int64) {
        self.esi = esi
        self.characterID = characterID
    }
    
    override class var activityCategory: UIActivity.Category {
        .share
    }
    
    override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType(rawValue: "com.shimanski.neocom.fitting")
    }
    
    override var activityTitle: String? {
        NSLocalizedString("Save In-Game", comment: "")
    }
    
    override var activityImage: UIImage? {
        UIImage(named: "eveLogo")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        activityItems.contains {$0 is Ship}
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        print(#function)
    }
    
    override func perform() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.activityDidFinish(true)
        }
        
    }
    
    override var activityViewController: UIViewController? {
//        esi.characters.characterID(1).fittings().post(fitting: <#T##ESI.Characters.CharacterID.Fittings.Fitting#>)
        UIHostingController(rootView: ActivityIndicator())
    }
}

struct InGameActivityView<P: Publisher>: View where P.Output == Void, P.Failure == Never {
    
    var body: some View {
        ActivityIndicator()
    }
}

//struct InGameActivity_Previews: PreviewProvider {
//    static var previews: some View {
//        InGameActivityView()
//    }
//}
