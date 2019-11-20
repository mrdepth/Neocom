//
//  FleetCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 26/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class FleetCell: RowCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var stackView: UIStackView!
	@IBOutlet weak var scrollView: UIScrollView!
	
	override func prepareForReuse() {
		super.prepareForReuse()
		scrollView.contentOffset = .zero
	}
}

extension Prototype {
	enum FleetCell {
		static let `default` = Prototype(nib: UINib(nibName: "FleetCell", bundle: nil), reuseIdentifier: "FleetCell")
	}
}

extension Tree.Item {
	class FleetFetchedResultsRow: FetchedResultsRow<Fleet> {
		override var prototype: Prototype? {
			return Prototype.FleetCell.default
		}
		
		lazy var types: [SDEInvType] = {
			let context = Services.sde.viewContext
			return (result.loadouts?.array as? [Loadout])?.compactMap{context.invType(Int($0.typeID))} ?? []
		}()
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? FleetCell else {return}
			cell.stackView.arrangedSubviews.forEach {
				cell.stackView.removeArrangedSubview($0)
			}
			types.compactMap{$0.icon?.image?.image}.forEach {
				let imageView = UIImageView(image: $0)
				imageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
				imageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
				cell.stackView.addArrangedSubview(imageView)
			}
		}
	}
}
