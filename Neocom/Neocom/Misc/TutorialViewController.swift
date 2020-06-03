//
//  TutorialViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

class TutorialViewController<Content: View>: UIHostingController<Content> {
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .didFinishStartup, object: nil)
    }
}
