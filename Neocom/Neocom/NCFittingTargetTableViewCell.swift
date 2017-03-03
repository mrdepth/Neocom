//
//  NCFittingTargetTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData


class NCFittingTargetTableViewCell: NCTableViewCell {
	@IBOutlet weak var collectionView: UICollectionView!
}

extension Prototype {
	struct NCFittingTargetTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCFittingTargetTableViewCell")
	}
}


class NCFittingTargetCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var typeNameLabel: UILabel!
	@IBOutlet weak var shipNameLabel: UILabel!
	var ship: NCFittingShip?
	
	lazy var type: NCDBInvType? = {
		guard let ship = self.ship else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[ship.typeID]
	}()
	
	override func awakeFromNib() {
		imageView.layer.borderColor = UIColor.caption.cgColor
		imageView.layer.borderWidth = 0
	}
	
	override var isSelected: Bool {
		didSet {
			imageView.layer.borderWidth = isSelected ? 1.0 : 0.0
//			imageView.tintColor = isSelected ? .caption : .placeholder
		}
	}
	
}

class NCFittingTargetRow: TreeRow, UICollectionViewDataSource, UICollectionViewDelegate {
	let modules: [NCFittingModule]
	let target: NCFittingShip?
	let targets: [NCFittingShip]
	
	private var contentOffset: CGPoint?
	
	init(modules: [NCFittingModule]) {
		self.modules = modules
		self.target = modules.first?.target
		let currentShip = modules.first?.owner as? NCFittingShip
		var targets = [NCFittingShip]()
		for pilot in (currentShip?.owner?.owner as? NCFittingGang)?.pilots ?? [] {
			guard let ship = pilot.ship, ship !== currentShip else {continue}
			targets.append(pilot.ship!)
		}
		self.targets = targets
		super.init(prototype: Prototype.NCFittingCharactersTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingCharactersTableViewCell else {return}
		
		cell.collectionView.dataSource = self
		cell.collectionView.delegate = self
		
		var indexPath: IndexPath?
		
		if let target = self.target, let i = targets.index(of: target) {
			indexPath = IndexPath(item: i, section: 1)
		}
		else {
			indexPath = IndexPath(item: 0, section: 1)
		}
		
		cell.collectionView.reloadData()
		cell.collectionView.layoutIfNeeded()
		
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
	
	override func move(from: TreeNode) -> TreeNodeReloading {
		contentOffset = (from as? NCFittingTargetRow)?.contentOffset
		return .dontReload
	}
	
	override var hashValue: Int {
		return modules.first?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingTargetRow)?.hashValue == hashValue
	}
	
	//MARK: - UICollectionViewDataSource
	
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 1
		case 1:
			return targets.count
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
