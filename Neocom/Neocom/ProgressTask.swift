//
//  ProgressTask.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class ProgressTask {
	enum Indicator {
		enum Container {
			case view(UIView)
			case viewController(UIViewController)
		}
		case activity(UIView)
		case progressBar(Container)
	}
	
	let progress: Progress
	let indicator: Indicator
	private let totalProgress: Progress
	private let fakeProgress: Progress
	private var observer: NSKeyValueObservation?

	init(progress: Progress, indicator: Indicator) {
		self.progress = progress
		self.indicator = indicator
		
		totalProgress = Progress(totalUnitCount:3)
		totalProgress.becomeCurrent(withPendingUnitCount: 1)
		fakeProgress = Progress(totalUnitCount:100)
		totalProgress.resignCurrent()
		totalProgress.addChild(progress, withPendingUnitCount: 2)
		
		
		observer = totalProgress.observe(\Progress.fractionCompleted) { [weak self] (progress, change) in
			self?.didUpdate(progress.fractionCompleted)
		}
	}
	
	func didUpdate(_ fractionCompleted: Double) {
	}
	
	private var _progressView: UIProgressView?
	
	private var progressView: UIProgressView? {
		get {
			if let progressView = _progressView {
				return progressView
			}
			else {
				guard case let .progressBar(container) = indicator else {return nil}
				
				func makeProgressView(in containerView: UIView) -> UIProgressView {
					let progressView = UIProgressView(progressViewStyle: .default)
					progressView.layer.zPosition = 1000;
					progressView.translatesAutoresizingMaskIntoConstraints = false
					progressView.progressTintColor = UIColor.progressTint
					progressView.trackTintColor = UIColor.clear
					containerView.addSubview(progressView)
					
					progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
					progressView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.0).isActive = true
					
					return progressView
				}
				
				switch container {
				case let .view(containerView):
					guard containerView.window != nil else {return nil}
					let progressView = makeProgressView(in: containerView)
					progressView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
					containerView.layoutIfNeeded()
					_progressView = progressView
					return progressView

				case let .viewController(viewController):
					let controller = sequence(first: viewController, next: {$0.parent}).reversed()
						.first {$0.parent is UINavigationController} ?? viewController
					let containerView: UIView = controller.view
					guard containerView.window != nil else {return nil}
					let progressView = makeProgressView(in: containerView)

					if let navigationBar = controller.navigationController?.navigationBar, navigationBar.window != nil {
						let c = progressView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor)
						c.priority = UILayoutPriority.defaultLow
						c.isActive = true
						progressView.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor).isActive = true
						
						navigationBar.superview?.layoutIfNeeded()
						_progressView = progressView
						return progressView

					}
					else {
						progressView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
						containerView.layoutIfNeeded()
						_progressView = progressView
						return progressView
					}
				}
			}
		}
	}
}
