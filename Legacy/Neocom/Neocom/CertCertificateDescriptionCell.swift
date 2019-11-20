//
//  CertCertificateDescriptionCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/28/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class CertCertificateDescriptionCell: HeaderCell {
	@IBOutlet var titleLabel: UILabel?
	@IBOutlet var iconView: UIImageView?
	@IBOutlet var descriptionTextView: UITextView?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		descriptionTextView?.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.caption]
		descriptionTextView?.textContainerInset = .zero
		descriptionTextView?.textContainer.lineFragmentPadding = 0
		descriptionTextView?.layoutManager.usesFontLeading = false
	}
}

extension Prototype {
	enum CertCertificateDescriptionCell {
		static let `default` = Prototype(nib: UINib(nibName: "CertCertificateDescriptionCell", bundle: nil), reuseIdentifier: "CertCertificateDescriptionCell")
	}
}


extension Tree.Content {
	struct CertCertificateDescription: Hashable {
		var prototype: Prototype?
		var title: String
		var image: UIImage?
		var certDescription: NSAttributedString?
	}
}

extension Tree.Content.CertCertificateDescription: CellConfigurable {
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? CertCertificateDescriptionCell else {return}
		cell.titleLabel?.text = title
		cell.iconView?.image = image
		
		cell.descriptionTextView?.attributedText = certDescription?.withFont(cell.descriptionTextView!.font!, textColor: cell.descriptionTextView!.textColor!)
	}
}
