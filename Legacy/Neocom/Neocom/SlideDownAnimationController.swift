//
//  SlideDownAnimationController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

fileprivate let TransitionThreshold: CGFloat = 50

class SlideDownAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
	
	public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return transitionContext?.isAnimated == true ? 0.35 : 0
	}
	
	public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let toView = transitionContext.view(forKey: .to) else {return}
		guard let fromView = transitionContext.view(forKey: .from) else {return}
		guard let toVC = transitionContext.viewController(forKey: .to) else {return}
		guard let fromVC = transitionContext.viewController(forKey: .from) else {return}
		let containerView = transitionContext.containerView
		let isPresenting = toVC.presentingViewController == fromVC
		
		if isPresenting {
			containerView.addSubview(toView)
		}
		else {
			containerView.insertSubview(toView, belowSubview: fromView)
		}

		let frame = transitionContext.initialFrame(for: fromVC)
		
		toView.frame = frame.offsetBy(dx: 0, dy: isPresenting ? -frame.height : frame.height)
		fromView.frame = frame
		
		toView.isHidden = false
		fromView.isHidden = false
		UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, options: [.curveEaseInOut], animations: {
			let r = frame.offsetBy(dx: 0, dy: isPresenting ? frame.height : -frame.height)
			fromView.center = CGPoint(x: r.midX, y: r.midY)
			toView.frame = frame
		}, completion: {(finished) -> Void in
			transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
		})
	}
	
}

class SlideDownInteractiveTransition: UIPercentDrivenInteractiveTransition {
	
	private var presenting: Bool = false
	private var distance: CGFloat = 0
	private var containerView: UIView? = nil
	private let panGestureRecognizer: UIPanGestureRecognizer
	
	init(panGestureRecognizer: UIPanGestureRecognizer) {
		self.panGestureRecognizer = panGestureRecognizer
		super.init()
		panGestureRecognizer.addTarget(self, action: #selector(onPan(_:)))
	}
	
	override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
		super.startInteractiveTransition(transitionContext)
		guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {return}
		guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else {return}
		containerView = transitionContext.containerView
		presenting = toVC.presentingViewController == fromVC
		distance = transitionContext.initialFrame(for: fromVC).size.height
	}
	
	deinit {
		panGestureRecognizer.removeTarget(self, action: #selector(onPan(_:)))
	}
	
	@objc func onPan(_ recognizer: UIPanGestureRecognizer) {
		let t = recognizer.translation(in: containerView)
		let p = t.y / self.distance
		switch recognizer.state {
		case .changed:
			if presenting {
				if p > 0 {
					self.update(p)
				}
				else {
					self.update(0)
				}
			}
			else {
				if p < 0 {
					self.update(-p)
				}
				else {
					self.update(0)
				}
			}
		case .ended:
			let v = recognizer.velocity(in: containerView)
			let t = recognizer.translation(in: containerView)
			
			if (presenting && v.y > 0) || (!presenting && v.y < 0) {
				self.finish()
			}
			else if v.y == 0 && ((presenting && t.y > TransitionThreshold) || (!presenting && t.y < TransitionThreshold)) {
				self.finish()
			}
			else {
				self.cancel()
			}
		case .cancelled:
			self.cancel()
		default:
			break
		}
	}
}

