//
//  MainMenuHeaderViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

class MainMenuHeaderViewController: UIViewController, ContentProviderView {
	@IBOutlet weak var characterNameLabel: UILabel?
	@IBOutlet weak var characterImageView: UIImageView?
	@IBOutlet weak var corporationLabel: UILabel?
	@IBOutlet weak var allianceLabel: UILabel?
	@IBOutlet weak var corporationImageView: UIImageView?
	@IBOutlet weak var allianceImageView: UIImageView?

	lazy var presenter: MainMenuHeaderPresenter! = MainMenuHeaderPresenter(view: self)
	var unwinder: Unwinder?
	
	func present(_ content: MainMenuHeaderInteractor.Info) -> Future<Void> {
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

	struct Metrics {
		var characterImageDimension: Int
		var corporationImageDimension: Int
		var allianceImageDimension: Int
	}
	
	var metrics: Metrics {
		return Metrics(characterImageDimension: 128, corporationImageDimension: 32, allianceImageDimension: 32)
	}
}
