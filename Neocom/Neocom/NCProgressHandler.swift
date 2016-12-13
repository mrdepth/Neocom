//
//  NCProgressHandler.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCProgressHandler: NSObject {
	private var progress: Progress
	private var totalProgress: Progress
	private var fakeProgress: Progress
	private var strongRefToSelf: AnyObject?
	private var progressView: UIProgressView?
	private var timer: Timer?
	private var viewController: UIViewController

	init(viewController: UIViewController, totalUnitCount: Int64) {
		self.viewController = viewController;
		
		totalProgress = Progress(totalUnitCount:3)
		totalProgress.becomeCurrent(withPendingUnitCount: 1)
		fakeProgress = Progress(totalUnitCount:100)
		totalProgress.resignCurrent()
		totalProgress.becomeCurrent(withPendingUnitCount: 2)
		progress = Progress(totalUnitCount:totalUnitCount)
		totalProgress.resignCurrent()
		
		super.init()
		timer = Timer(timeInterval: 0.1, target: self, selector: #selector(timerTick(_:)), userInfo: nil, repeats: true)
		RunLoop.main.add(timer!, forMode: .defaultRunLoopMode)
	}
	
	deinit {
		timer?.invalidate()
		if let progressView = progressView {
			if Thread.isMainThread {
				progressView.removeFromSuperview()
			}
			else {
				DispatchQueue.main.async {
					progressView.removeFromSuperview()
				}
			}
		}
	}
	
	func timerTick(_ timer: Timer) {
		
	}
}
