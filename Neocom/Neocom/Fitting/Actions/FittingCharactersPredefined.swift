//
//  FittingCharactersPredefined.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.03.2020.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct FittingCharactersPredefined: View {
	
	private func level(_ l: Int) -> String {
		l == 0 ? "0" : String(roman: l)
	}
	
    var body: some View {
		Section(header: Text("PREDEFINED")) {
			ForEach(0..<5) { i in
				FittingCharacterCell(i)
			}
		}
    }
}

struct FittingCharactersPredefined_Previews: PreviewProvider {
    static var previews: some View {
		List {
			FittingCharactersPredefined()
		}.listStyle(GroupedListStyle())
    }
}
