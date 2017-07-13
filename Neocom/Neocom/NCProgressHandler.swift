//
//  NCProgressHandler.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCProgressHandler: NSObject {
	let progress: Progress
	private let totalProgress: Progress
	private let fakeProgress: Progress
	private var timer: Timer?
	weak var viewController: UIViewController?
	weak var view: UIView?
	private var activityIndicatorView: UIActivityIndicatorView?
	
	init(totalUnitCount: Int64) {
		totalProgress = Progress(totalUnitCount:3)
		totalProgress.becomeCurrent(withPendingUnitCount: 1)
		fakeProgress = Progress(totalUnitCount:100)
		totalProgress.resignCurrent()
		totalProgress.becomeCurrent(withPendingUnitCount: 2)
		progress = Progress(totalUnitCount:totalUnitCount)
		totalProgress.resignCurrent()
		super.init()
		totalProgress.addObserver(self, forKeyPath: "fractionCompleted", options: [], context: nil)
		timer = Timer(timeInterval: 0.1, target: self, selector: #selector(timerTick(_:)), userInfo: nil, repeats: true)
		RunLoop.main.add(timer!, forMode: .defaultRunLoopMode)
	}

	convenience init(viewController: UIViewController, totalUnitCount: Int64) {
		self.init(totalUnitCount: totalUnitCount)
		self.viewController = viewController;
	}

	convenience init(view: UIView, totalUnitCount: Int64) {
		self.init(totalUnitCount: totalUnitCount)
		self.view = view
	}

	convenience init(view: UIView, totalUnitCount: Int64, activityIndicatorStyle style: UIActivityIndicatorViewStyle) {
		self.init(totalUnitCount: totalUnitCount)
		self.view = view
		activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: style)
		activityIndicatorView?.translatesAutoresizingMaskIntoConstraints = true
		activityIndicatorView?.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
		view.addSubview(activityIndicatorView!)
		activityIndicatorView?.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
//		activityIndicatorView?.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//		activityIndicatorView?.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
	}

	deinit {
		totalProgress.removeObserver(self, forKeyPath: "fractionCompleted")
		self.finish()
	}
	
	private var _progressView: UIProgressView?

	private var progressView: UIProgressView? {
		get {
			if let progressView = _progressView {
				return progressView
			}
			else {
				var viewController = self.viewController
				while viewController?.parent?.isKind(of: UINavigationController.self) == false {
					viewController = viewController?.parent
				}
				
				guard let container = viewController?.view ?? view else {return nil}
				guard container.window != nil else {return nil}
				

				let progressView = UIProgressView(progressViewStyle: .default)
				progressView.layer.zPosition = 1000;
				progressView.translatesAutoresizingMaskIntoConstraints = false
				progressView.progressTintColor = UIColor.progressTint
				progressView.trackTintColor = UIColor.clear
				container.addSubview(progressView)
				
				progressView.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
				progressView.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 1.0).isActive = true
				
				if let navigationBar = viewController?.navigationController?.navigationController?.navigationBar ?? viewController?.navigationController?.navigationBar {
					let c = progressView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor)
					c.priority = UILayoutPriorityDefaultLow
					c.isActive = true
					progressView.topAnchor.constraint(greaterThanOrEqualTo: viewController!.view.topAnchor).isActive = true
					
					navigationBar.superview?.layoutIfNeeded()
				}
				else {
					progressView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
				}
				container.layoutIfNeeded()
				_progressView = progressView
				return progressView
			}
		}
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "fractionCompleted" {
			DispatchQueue.main.async {
				guard self.timer != nil else {return}
				if self.totalProgress.fractionCompleted >= 1 {
					self.finish()
				}
				else if self.activityIndicatorView == nil {
					self.progressView?.setProgress(Float(self.totalProgress.fractionCompleted), animated: true)
				}
			}
		}
	}
	
	func finish() {
		timer?.invalidate()
		timer = nil
		let views = ([_progressView, activityIndicatorView] as [UIView?]).flatMap({$0})
		if views.count > 0 {
			if Thread.isMainThread {
				views.forEach ({$0.removeFromSuperview()})
			}
			else {
				DispatchQueue.main.async {
					views.forEach ({$0.removeFromSuperview()})
				}
			}
		}
	}
	
	@objc private func timerTick(_ timer: Timer) {
		fakeProgress.completedUnitCount += 5
		if fakeProgress.fractionCompleted >= 1 {
			timer.invalidate()
			self.timer = nil
		}
	}
}
