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
	
	override func awakeFromNib() {
		imageView.layer.borderColor = UIColor.caption.cgColor
		imageView.layer.borderWidth = 0
	}
	
	override var isSelected: Bool {
		didSet {
			imageView.layer.borderWidth = isSelected ? 1.0 : 0.0
			imageView.tintColor = isSelected ? .caption : .placeholder
			titleLabel.textColor = isSelected ? .caption : .white
		}
	}
	
}

class NCFittingCharactersRow: TreeRow, UICollectionViewDataSource, UICollectionViewDelegate {
	let pilot: NCFittingCharacter
	
	private lazy var accounts: [NCAccount] = {
		return NCStorage.sharedStorage?.viewContext.fetch("Account", sortedBy: [NSSortDescriptor(key: "characterName", ascending: true)]) ?? []
	}()
	
	private var contentOffset: CGPoint?
	
	init(pilot: NCFittingCharacter) {
		self.pilot = pilot
		super.init(cellIdentifier: "NCFittingCharactersTableViewCell", segue: "asdf")
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingCharactersTableViewCell else {return}
		
		cell.collectionView.dataSource = self
		cell.collectionView.delegate = self
		
		var indexPath: IndexPath?
		
		pilot.engine?.performBlockAndWait {
			if let url = self.pilot.url {
				if let i = self.accounts.index(where: {NCFittingCharacter.url(account: $0) == url}) {
					indexPath = IndexPath(item: i, section: 0)
				}
				else if let i = [0,1,2,3,4,5].index(where: {NCFittingCharacter.url(level: $0) == url}) {
					indexPath = IndexPath(item: i, section: 1)
				}
			}
		}
		
		if let contentOffset = contentOffset {
			cell.collectionView.contentOffset = contentOffset
			if let indexPath = indexPath {
				cell.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
			}

		}
		else {
			if let indexPath = indexPath {
				DispatchQueue.main.async {
					cell.collectionView.layoutIfNeeded()
					cell.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [.centeredHorizontally])
				}
			}
		}

	}
	
	override func changed(from: TreeNode) -> Bool {
		contentOffset = (from as? NCFittingCharactersRow)?.contentOffset
		return false
	}
	
	override var hashValue: Int {
		return pilot.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingCharactersRow)?.hashValue == hashValue
	}
	
	//MARK: - UICollectionViewDataSource
	
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch section {
		case 0:
			return accounts.count
		case 1:
			return NCFittingCharactersRow.titles.count
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
			//cell.titleLabel.attributedText = NSLocalizedString("All Skills", comment: "") + "\n" + (NCFittingCharactersRow.titles[indexPath.item] * [NSForegroundColorAttributeName: UIColor.caption])
			cell.titleLabel.text = NSLocalizedString("All Skills", comment: "") + "\n" + NCFittingCharactersRow.titles[indexPath.item]
			cell.imageView.image = placeholder(level: indexPath.item)
			cell.object = indexPath.item
		default:
			break
		}
		return cell
	}
	
	//MARK: - UICollectionViewDelegate
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let cell = collectionView.cellForItem(at: indexPath) as? NCFittingCharacterCollectionViewCell else {return}
		switch cell.object {
		case let account as NCAccount:
			let progress = NCProgressHandler(view: cell, totalUnitCount: 1, activityIndicatorStyle: .white)
			pilot.setSkills(from: account) { _ in
				progress.finish()
			}
		case let level as Int:
			let progress = NCProgressHandler(view: cell, totalUnitCount: 1, activityIndicatorStyle: .white)
			pilot.setSkills(level: level) { _ in
				progress.finish()
			}
		default:
			break
		}
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		contentOffset = scrollView.contentOffset
	}
	
	//MARK: - Private
	
	private var placeholders = [Int: UIImage]()
	private static var titles = ["0", "I", "II", "III", "IV", "V"]
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
