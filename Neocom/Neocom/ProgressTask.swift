//
//  ProgressTask.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

protocol ProgressIndicatorContainer {}
extension UIView: ProgressIndicatorContainer {}
extension UIViewController: ProgressIndicatorContainer {}

class ProgressTask {
	enum Indicator {
		case activity(UIView, UIActivityIndicatorView.Style)
		case progressBar(ProgressIndicatorContainer)
	}
	
	private let progress: Progress
	let indicator: Indicator
	private let totalProgress: Progress
	private let fakeProgress: Progress
	private var observer: NSKeyValueObservation?
	private var timer: Timer?

	init(progress: Progress, indicator: Indicator) {
		self.progress = progress
		self.indicator = indicator
		
		totalProgress = Progress(totalUnitCount:3)
		totalProgress.becomeCurrent(withPendingUnitCount: 1)
		fakeProgress = Progress(totalUnitCount:100)
		totalProgress.resignCurrent()
		totalProgress.addChild(progress, withPendingUnitCount: 2)
		
		timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] timer in
			guard let strongSelf = self else {return}
			strongSelf.fakeProgress.completedUnitCount += 10
			if strongSelf.fakeProgress.completedUnitCount >= 100 {
				timer.invalidate()
				strongSelf.timer = nil
			}
		}
		RunLoop.main.add(timer!, forMode: .default)
		
		observer = totalProgress.observe(\Progress.fractionCompleted) { [weak self] (progress, change) in
			if Thread.isMainThread {
				self?.didUpdate(progress.fractionCompleted)
			}
			else {
				DispatchQueue.main.async {
					self?.didUpdate(progress.fractionCompleted)
				}
			}
		}
		
		if case let .activity(containerView, style) = indicator {
			activityIndicatorView = UIActivityIndicatorView(style: style)
			activityIndicatorView?.translatesAutoresizingMaskIntoConstraints = true
			activityIndicatorView?.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
			containerView.addSubview(activityIndicatorView!)
			activityIndicatorView?.startAnimating()
			activityIndicatorView?.center = CGPoint(x: containerView.bounds.midX, y: containerView.bounds.midY)
		}
	}
	
	public func performAsCurrent<ReturnType>(withPendingUnitCount unitCount: Int64, using work: () throws -> ReturnType) rethrows -> ReturnType {
		if Progress.current() == totalProgress {
			totalProgress.resignCurrent()
		}
		totalProgress.becomeCurrent(withPendingUnitCount: unitCount)

		defer {
			if Progress.current() == totalProgress {
				totalProgress.resignCurrent()
			}
		}
		let result = try work()
		return result
	}
	
	deinit {
		finalize()
	}
	
	private func finalize() {
		let timer = self.timer
		self.timer = nil
		let progressView = _progressView
		_progressView = nil
		let activityIndicatorView = self.activityIndicatorView
		self.activityIndicatorView = nil

		if Thread.isMainThread {
			timer?.invalidate()
			progressView?.removeFromSuperview()
			activityIndicatorView?.removeFromSuperview()
		}
		else {
			DispatchQueue.main.async {
				timer?.invalidate()
				progressView?.removeFromSuperview()
				activityIndicatorView?.removeFromSuperview()
			}
		}
	}
	
	private func didUpdate(_ fractionCompleted: Double) {
		if case .progressBar = indicator, let progressView = progressView {
			progressView.setProgress(Float(fractionCompleted), animated: true)
		}
	}
	
	private var activityIndicatorView: UIActivityIndicatorView?
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
				case let containerView as UIView:
					guard containerView.window != nil else {return nil}
					let progressView = makeProgressView(in: containerView)
					progressView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
					containerView.layoutIfNeeded()
					_progressView = progressView
					return progressView

				case let viewController as UIViewController:
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
				default:
					return nil
				}
			}
		}
	}
}
