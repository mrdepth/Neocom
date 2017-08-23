//
//  NCSlideDownDismissalInteractiveTransitioning.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCSlideDownDismissalInteractiveTransitioning: UIPercentDrivenInteractiveTransition {
	static var associationKey = "slideDownDismissalInteractiveTransitioning"
	weak var viewController: UIViewController?
	
	class func add(to viewController: UIViewController) {
		let interactor = NCSlideDownDismissalInteractiveTransitioning(viewController: viewController)
		viewController.transitioningDelegate = interactor
		objc_setAssociatedObject(viewController, &NCSlideDownDismissalInteractiveTransitioning.associationKey, interactor, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
	
	init(viewController: UIViewController) {
		self.viewController = viewController
		super.init()
		let recognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
		recognizer.delegate = self
		viewController.view.addGestureRecognizer(recognizer)
	}
	
	fileprivate(set) var isInteractive: Bool = false
	
	override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
		super.startInteractiveTransition(transitionContext)
	}
	
	func onPan(_ recognizer: UIPanGestureRecognizer) {
		switch recognizer.state {
		case .began:
			break
		case .changed:
			let t = recognizer.translation(in: nil)
			if viewController?.transitionCoordinator == nil {
				if fabs(t.x) > 10 && fabs(t.x) > t.y {
					recognizer.isEnabled = false
					recognizer.isEnabled = true
				}
				else {
					isInteractive = true
					viewController?.dismiss(animated: true, completion: nil)
				}
			}
			else {
				update(t.y / recognizer.view!.bounds.size.height)
			}
			
		case .ended:
			let v = recognizer.velocity(in: recognizer.view)
			let t = recognizer.translation(in: recognizer.view)
			if v.y >= 0 && t.y > 40 {
				finish()
			}
			else {
				cancel()
			}
			isInteractive = false
		case .cancelled:
			cancel()
			isInteractive = false
		default:
			break
		}
	}
}

extension NCSlideDownDismissalInteractiveTransitioning: UIViewControllerTransitioningDelegate {
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return isInteractive ? self : nil
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return isInteractive ? self : nil
	}
}

extension NCSlideDownDismissalInteractiveTransitioning: UIViewControllerAnimatedTransitioning {
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return transitionContext?.isAnimated == true ? 0.25 : 0
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let from = transitionContext.view(forKey: .from),
			let fromVC = transitionContext.viewController(forKey: .from)
			else {return}
		let to = transitionContext.view(forKey: .to)
		if let to = to, let toVC = transitionContext.viewController(forKey: .to) {
			transitionContext.containerView.insertSubview(to, belowSubview: from)
			to.frame = transitionContext.finalFrame(for: toVC)
		}

		UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveLinear], animations: {
			from.frame.origin.y = transitionContext.finalFrame(for: fromVC).maxY
		}, completion: { finished in
			transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
		})
	}
}

extension NCSlideDownDismissalInteractiveTransitioning: UIGestureRecognizerDelegate {
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer else {return true}
		let t = recognizer.translation(in: nil)
		guard t.y > 0 else {return false}
		guard (viewController?.childViewControllers.last as? UITableViewController)?.refreshControl == nil else {return false}

		let hitTest = gestureRecognizer.view?.hitTest(gestureRecognizer.location(in: gestureRecognizer.view), with: nil)
		if let tableView = hitTest?.ancestor(of: UITableView.self), tableView.contentOffset.y > -tableView.contentInset.top {
			return false
		}

		
		return hitTest?.ancestor(of: UIPickerView.self) == nil
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
//		return !(otherGestureRecognizer is UIPanGestureRecognizer)
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		guard otherGestureRecognizer is UIPanGestureRecognizer else {return false}
		return true
	}
}
