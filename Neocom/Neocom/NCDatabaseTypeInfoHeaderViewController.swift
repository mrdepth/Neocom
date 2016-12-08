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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		titleLabel.text = type?.typeName
		textView.attributedText = type?.typeDescription?.text?.withFont(textView.font!, textColor: textView.textColor!)
		imageView.image = (type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image) as? UIImage
	}
}
