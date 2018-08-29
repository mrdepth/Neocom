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
	
	func present(_ content: MainHeaderInteractor.Info) -> Future<Void> {
		characterNameLabel?.text = content.characterName
		characterImageView?.image = content.characterImage
		corporationLabel?.text = content.corporation
		allianceLabel?.text = content.alliance
		corporationImageView?.image = content.corporationImage
		allianceImageView?.image = content.allianceImage
		return .init(())
	}
	
	func fail(_ error: Error) {
	}

}
