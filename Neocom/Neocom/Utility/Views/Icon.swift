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
		case normal
        case small
	}
	let image: Image
	let size: Size
	
	init(_ image: Image, size: Size = .normal) {
		self.image = image
		self.size = size
	}
	
    var body: some View {
        let s: CGSize
        switch size {
        case .normal:
            s = CGSize(width: 32, height: 32)
        case .small:
            s = CGSize(width: 20, height: 20)
        }
        return image.resizable().scaledToFit().frame(width: s.width, height: s.height)
    }
}

struct Icon_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Icon(Image("character"))
            Icon(Image("character"), size: .small)
        }
    }
}
