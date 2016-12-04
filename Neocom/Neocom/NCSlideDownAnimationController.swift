//
//  NCSlideDownAnimationController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCSlideDownAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
	
	public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return transitionContext?.isAnimated ?? false ? 0.35 : 0
	}
	
	public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {return}
		guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) else {return}
		guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {return}
		guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else {return}
		let containerView = transitionContext.containerView
		
		containerView.addSubview(toView)
		
		let isPresenting = toVC.presentingViewController == fromVC
		
		let initialFrame = transitionContext.initialFrame(for: fromVC)
		let finalFrame = transitionContext.finalFrame(for: toVC)
		toView.frame = CGRect(origin: CGPoint(x: finalFrame.origin.x, y: isPresenting ? initialFrame.origin.y - finalFrame.size.height : initialFrame.maxY), size: finalFrame.size)
		
		UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, options: [.curveEaseInOut], animations: {
			toView.frame = finalFrame
			fromView.frame = CGRect(origin: CGPoint(x: initialFrame.origin.x, y: isPresenting ? finalFrame.maxY : finalFrame.origin.y - initialFrame.size.height), size: initialFrame.size)
		}, completion: {(finished) -> Void in
			transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
		})
	}

}

class NCSlideDownInteractiveTransition: UIPercentDrivenInteractiveTransition {
	
	private let scrollView: UIScrollView
	private var presenting: Bool = false
	private var startPanOffset: CGFloat = 0
	private var startContentOffset: CGPoint = CGPoint()
	private var distance: CGFloat = 0
	private var containerView: UIView? = nil
	
	init (scrollView: UIScrollView) {
		self.scrollView = scrollView
		super.init()
		self.scrollView.panGestureRecognizer.addTarget(self, action: #selector(NCSlideDownInteractiveTransition.onPan(_:)))
	}
	
	override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
		guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {return}
		guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else {return}
		containerView = transitionContext.containerView
		presenting = toVC.presentingViewController == fromVC
		startPanOffset = scrollView.panGestureRecognizer.translation(in: containerView).y
		startContentOffset = scrollView.contentOffset
		distance = transitionContext.initialFrame(for: fromVC).size.height
	}
	
	deinit {
		self.scrollView.panGestureRecognizer.removeTarget(self, action: #selector(NCSlideDownInteractiveTransition.onPan(_:)))
	}
	
	func onPan(_ recognizer: UIPanGestureRecognizer) {
		let t = recognizer.translation(in: containerView)
		let p = (t.y - startPanOffset) / self.distance
		switch recognizer.state {
		case .changed:
			if presenting {
				if p > 0 {
					scrollView.contentOffset = startContentOffset
				}
				else {
					self.update(p)
				}
			}
			else {
				if p < 0 {
					self.update(-p)
					self.scrollView.contentOffset = startContentOffset
				}
				else {
					self.update(0)
				}
			}
		case .ended:
			if (presenting && p > 0) || (!presenting && p < 0) {
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
