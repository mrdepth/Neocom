//
//  Icon.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct Icon: View {
	enum Size {
		case `default`
	}
	let image: Image
	let size: Size
	
	init(_ image: Image, size: Size = .default) {
		self.image = image
		self.size = size
	}
	
    var body: some View {
        image.resizable().scaledToFit().frame(width: 32, height: 32)
    }
}

struct Icon_Previews: PreviewProvider {
    static var previews: some View {
		Icon(Image("character"))
    }
}
