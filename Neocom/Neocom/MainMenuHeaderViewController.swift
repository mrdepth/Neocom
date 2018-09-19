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
	typealias Presenter = MainMenuHeaderPresenter
	
	lazy var presenter: Presenter! = Presenter(view: self)
	var unwinder: Unwinder?
	
	@IBOutlet weak var characterNameLabel: UILabel?
	@IBOutlet weak var characterImageView: UIImageView?
	@IBOutlet weak var corporationLabel: UILabel?
	@IBOutlet weak var allianceLabel: UILabel?
	@IBOutlet weak var corporationImageView: UIImageView?
	@IBOutlet weak var allianceImageView: UIImageView?

	override func viewDidLoad() {
		super.viewDidLoad()
		presenter.configure()
		
		characterNameLabel?.text = " "
		characterImageView?.image = #imageLiteral(resourceName: "avatar")
		corporationLabel?.text = " "
		corporationImageView?.image = nil
		allianceLabel?.text = " "
		allianceImageView?.image = nil
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		presenter.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presenter.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		presenter.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		presenter.viewDidDisappear(animated)
	}
	
	@IBAction func onLogout(_ sender: Any) {
		presenter.onLogout()
	}
	
	@discardableResult
	func present(_ content: Presenter.Presentation, animated: Bool) -> Future<Void> {
		characterNameLabel?.text = content.characterName
		characterImageView?.image = content.characterImage
		corporationLabel?.text = content.corporation
		corporationImageView?.image = content.corporationImage
		allianceLabel?.text = content.alliance
		allianceImageView?.image = content.allianceImage
		return .init(())
	}
	
	func fail(_ error: Error) {
		characterNameLabel?.text = error.localizedDescription
		characterImageView?.image = #imageLiteral(resourceName: "avatar")
		corporationLabel?.text = " "
		corporationImageView?.image = nil
		allianceLabel?.text = " "
		allianceImageView?.image = nil
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
