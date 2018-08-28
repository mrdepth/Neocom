//
//  MainHeaderPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

class MainHeaderPresenter: ContentProviderPresenter {
	
	struct Info {
		var characterName: String?
		var characterImage: UIImage?
		var corporation: String?
		var alliance: String?
		var corporationImage: UIImage?
		var allianceImage: UIImage?
	}
	
	var presentation: CachedValue<Info>?
	var isLoading: Bool = false
	
	func presentation(for content: ()) -> Future<CachedValue<MainHeaderPresenter.Info>> {
		return .init(.failure(NCError.invalidImageFormat))
	}

	weak var view: MainHeaderViewController!
	lazy var interactor: MainHeaderInteractor! = MainHeaderInteractor(presenter: self)

	required init(view: MainHeaderViewController) {
		self.view = view
	}
}
