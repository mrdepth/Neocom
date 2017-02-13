//
//  NCFittingCharactersTableViewCell.swift
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

class NCFittingCharactersTableViewCell: NCTableViewCell {
	@IBOutlet weak var collectionView: UICollectionView!
	
}

class NCFittingCharacterCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	var object: Any?
	
}

class NCFittingCharactersRow: TreeRow, UICollectionViewDataSource {
	let pilot: NCFittingCharacter
	
	private lazy var accounts: [NCAccount] = {
		return NCStorage.sharedStorage?.viewContext.fetch("Account", sortedBy: [NSSortDescriptor(key: "characterName", ascending: true)]) ?? []
	}()
	
	init(pilot: NCFittingCharacter) {
		self.pilot = pilot
		super.init(cellIdentifier: "NCFittingCharactersTableViewCell", segue: "asdf")
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingCharactersTableViewCell else {return}
		cell.collectionView.dataSource = self
	}
	
	//MARK: - UICollectionViewDataSource
	
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch section {
		case 0:
			return accounts.count
		case 1:
			return 5
		default:
			return 0
		}
	}
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 2
	}
	
	
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NCFittingCharacterCollectionViewCell", for: indexPath) as! NCFittingCharacterCollectionViewCell
		switch indexPath.section {
		case 0:
			let account = accounts[indexPath.item]
			cell.titleLabel.text = account.characterName
			cell.object = account
			cell.imageView.image = nil
			NCDataManager(account: account).image(characterID: account.characterID, dimension: Int(cell.imageView.bounds.size.width)) { result in
				if (cell.object as? NCAccount) === account {
					switch result {
					case let .success(value, _):
						cell.imageView.image = value
					default:
						break
					}
				}
			}
			
		case 1:
			cell.titleLabel.attributedText = NSLocalizedString("All Skills", comment: "") + "\n" + (NCFittingCharactersRow.titles[indexPath.item] * [NSForegroundColorAttributeName: UIColor.caption])
			cell.imageView.image = placeholder(level: indexPath.item)
		default:
			break
		}
		return cell
	}
	
	private var placeholders = [Int: UIImage]()
	private static var titles = ["I", "II", "III", "IV", "V"]
	private func placeholder(level: Int) -> UIImage {
		if let image = placeholders[level] {
			return image
		}
		else {
			let image = UIImage.placeholder(text: NCFittingCharactersRow.titles[level], size: CGSize(width: 64, height: 64))
			placeholders[level] = image
			return image
		}
	}

}
