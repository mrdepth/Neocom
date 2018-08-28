//
//  MainHeaderViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

class MainHeaderViewController: UIViewController, ContentProviderView {
	@IBOutlet weak var characterNameLabel: UILabel?
	@IBOutlet weak var characterImageView: UIImageView?
	@IBOutlet weak var corporationLabel: UILabel?
	@IBOutlet weak var allianceLabel: UILabel?
	@IBOutlet weak var corporationImageView: UIImageView?
	@IBOutlet weak var allianceImageView: UIImageView?

	var presenter: MainHeaderPresenter!
	var input: Account?
	
	func present(_ content: CachedValue<MainHeaderPresenter.Info>) -> Future<Void> {
		let value = content.value
		characterNameLabel?.text = value.characterName
		characterImageView?.image = value.characterImage
		corporationLabel?.text = value.corporation
		allianceLabel?.text = value.alliance
		corporationImageView?.image = value.corporationImage
		allianceImageView?.image = value.allianceImage
		return .init(())
	}
	
	func fail(_ error: Error) {
		
	}

}
