//
//  NCAutoHeightLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCAutoHeightLabel: UILabel {

	override func draw(_ rect: CGRect) {
		guard let s = self.attributedText?.mutableCopy() as? NSMutableAttributedString else {return}
		let context = NSStringDrawingContext()
		let bounds = s.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: context)
		let scale = min(min(rect.size.width / bounds.size.width, rect.size.height / bounds.size.height), 1)
		let cgContext = UIGraphicsGetCurrentContext()
		cgContext?.saveGState()
		cgContext?.translateBy(x: rect.midX, y: rect.midY)
		cgContext?.scaleBy(x: scale, y: scale)
		cgContext?.translateBy(x: -bounds.midX, y: -bounds.midY)
		s.draw(with: bounds, options: [.usesLineFragmentOrigin], context: nil)
		cgContext?.restoreGState()
	}
	
}
