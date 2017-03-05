//
//  NCFittingCharacterTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

extension UIImage {
	class func placeholder(text: String, size: CGSize) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
		let context = UIGraphicsGetCurrentContext()

		let rect = CGRect(origin: .zero, size: size)

		context?.fill(rect)
		
		context?.setBlendMode(.clear)
		

		let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
		paragraph.alignment = .center
		let font = UIFont.boldSystemFont(ofSize: round(size.height * 0.7))
		let attributes = [NSFontAttributeName:font, NSParagraphStyleAttributeName: paragraph]
		let s = text * attributes
		let c = NSStringDrawingContext()
		c.minimumScaleFactor = 0.5
		s.draw(with: rect.insetBy(dx: 0, dy: (size.height - font.lineHeight) / 2), options: [.usesLineFragmentOrigin], context: nil)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysTemplate)
		UIGraphicsEndImageContext()
		return image!
	}
}

class NCFittingCharacterTableViewCell: NCTableViewCell {
	@IBOutlet weak var characterNameLabel: UILabel!
	@IBOutlet weak var characterImageView: UIImageView!
}

extension Prototype {
	struct NCFittingCharacterTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCFittingCharacterTableViewCell", bundle: nil), reuseIdentifier: "NCFittingCharacterTableViewCell")
	}
}

class NCFittingCharacterRow: TreeRow {
	let account: NCAccount?
	let level: Int?
	let url: URL?

	init(account: NCAccount, route: Route? = nil) {
		self.account = account
		self.level = nil
		url = NCFittingCharacter.url(account: account)
		super.init(prototype: Prototype.NCFittingCharacterTableViewCell.default, route: route)
	}
	
	init(level: Int, route: Route? = nil) {
		self.level = level
		self.account = nil
		url = NCFittingCharacter.url(level: level)
		super.init(prototype: Prototype.NCFittingCharacterTableViewCell.default, route: route)
	}
	
	private var image: UIImage?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingCharacterTableViewCell else {return}
		
		cell.characterImageView?.image = image
		
		if let account = account {
			cell.characterNameLabel.text = account.characterName
			cell.object = account
			if image == nil {
				NCDataManager(account: account).image(characterID: account.characterID, dimension: Int(cell.characterImageView.bounds.size.width)) { result in
					if (cell.object as? NCAccount) === account {
						switch result {
						case let .success(value, _):
							self.image = value
							if (cell.object as? NCAccount) == account {
								cell.characterImageView.image = value
							}
						default:
							break
						}
					}
				}
			}
		}
		else {
			let level = self.level ?? 0
			let s = NCFittingCharacterRow.titles[level]
			cell.characterNameLabel.text = NSLocalizedString("All Skills", comment: "") + " " + s
			if image == nil {
				image = UIImage.placeholder(text: s, size: cell.characterImageView.bounds.size)
				cell.characterImageView.image = image
			}
			cell.object = level
		}
	}
	
	override var hashValue: Int {
		return account?.hashValue ?? level?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingCharacterRow)?.hashValue == hashValue
	}
	
	private static var titles = ["0", "I", "II", "III", "IV", "V"]

}
