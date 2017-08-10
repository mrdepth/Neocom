//
//  NCDatabaseTypeInfoHeaderViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCDatabaseTypeInfoHeaderViewController: UIViewController {
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var textView: UITextView!
	
	var type: NCDBInvType?
	var image: UIImage?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
		titleLabel.text = type?.typeName
		
		var groups = [String]()
		var marketGroup = type?.marketGroup
		while let marketGroupName = marketGroup?.marketGroupName {
			groups.insert(marketGroupName, at: 0)
			marketGroup = marketGroup?.parentGroup
		}

		if !groups.isEmpty {
			subtitleLabel.text = groups.joined(separator: " / ")
		}
		else if let group = type?.group?.groupName, let category = type?.group?.category?.categoryName {
			subtitleLabel.text = "\(category) / \(group)"
		}
		else {
			subtitleLabel.text = nil
		}
		textView.attributedText = type?.typeDescription?.text?.withFont(textView.font!, textColor: textView.textColor!)
		textView.linkTextAttributes = [NSForegroundColorAttributeName: UIColor.caption]
		imageView.image = image ?? type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
	}
	
}
