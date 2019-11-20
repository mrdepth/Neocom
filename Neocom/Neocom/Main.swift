//
//  Main.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct Main: View {
    var body: some View {
		NavigationView {
			Text("Left")
				.navigationViewStyle(DoubleColumnNavigationViewStyle())
				.navigationBarTitle("One")
			Text("Right").navigationBarTitle("Two")
		}
    }
}

struct Main_Previews: PreviewProvider {
    static var previews: some View {
        Main()
    }
}
