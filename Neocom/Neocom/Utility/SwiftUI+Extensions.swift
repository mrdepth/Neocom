//
//  SwiftUI+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 16.12.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI


struct ServicesViewModifier: ViewModifier {
	var environment: EnvironmentValues

	func body(content: Content) -> some View {
		content.environment(\.managedObjectContext, environment.managedObjectContext)
			.environment(\.backgroundManagedObjectContext, environment.backgroundManagedObjectContext)
			.environment(\.esi, environment.esi)
			.environment(\.account, environment.account)
	}
}

struct BlockModifier<Result: View>: ViewModifier {
    var block: (Content) -> Result
    init(@ViewBuilder _ block: @escaping (Content) -> Result) {
        self.block = block
    }
    
    func body(content: Content) -> Result {
        block(content)
    }

}
