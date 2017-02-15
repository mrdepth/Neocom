//
//  NCSheetPresentationController.swift
//  Neocom
//
//  Created by Artem Shimanski on 31.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

fileprivate let cornerRadius = 16.0 as CGFloat

class NCSheetSegue: UIStoryboardSegue {
	override func perform() {
		let presentationController = NCSheetPresentationController(presentedViewController: destination, presenting: source)
		withExtendedLifetime(presentationController) {
			destination.transitioningDelegate = presentationController
			source.present(destination, animated: true, completion: nil)
		}
	}
}

class NCSheetPresentationController: UIPresentationController, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate {

	private var dimmingView: UIView?
	private var presentationWrappingView: UIView?
	private var keyboardFrame: CGRect = .zero
	private var panGestureRecognizer: UIPanGestureRecognizer?
	private var interactiveTransition: UIPercentDrivenInteractiveTransition?

	override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
		presentedViewController.modalPresentationStyle = .custom
		super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
	}
	
	override var presentedView: UIView? {
		return presentationWrappingView
	}
	
	override func presentationTransitionWillBegin() {
		guard let presentedViewControllerView = super.presentedView else {return}
		guard let containerView = self.containerView else {return}
		
		do {
			let presentationWrapperView = UIView(frame: frameOfPresentedViewInContainerView)
			presentationWrapperView.layer.shadowOpacity = 0.44
			presentationWrapperView.layer.shadowRadius = 13.0
			presentationWrapperView.layer.shadowOffset = CGSize(width: 0, height: -6)
			presentationWrappingView = presentationWrapperView
			
			let presentationRoundedCornerView = UIView(frame: UIEdgeInsetsInsetRect(presentationWrapperView.bounds, UIEdgeInsets(top: 0, left: 0, bottom: -cornerRadius * 2.0, right: 0)))
			presentationRoundedCornerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			presentationRoundedCornerView.layer.cornerRadius = cornerRadius
			presentationRoundedCornerView.layer.masksToBounds = true
			presentationRoundedCornerView.backgroundColor = .background
			
			let presentedViewControllerWrapperView = UIView(frame: UIEdgeInsetsInsetRect(presentationRoundedCornerView.bounds, UIEdgeInsets(top: 0, left: 0, bottom: cornerRadius * 2.0, right: 0)))
			presentedViewControllerWrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			
			presentedViewControllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			presentedViewControllerView.frame = presentedViewControllerWrapperView.bounds
			presentedViewControllerWrapperView.addSubview(presentedViewControllerView)
			
			presentationRoundedCornerView.addSubview(presentedViewControllerWrapperView)
			presentationWrapperView.addSubview(presentationRoundedCornerView)
			
			
			panGestureRecognizer?.view?.removeGestureRecognizer(panGestureRecognizer!)
			let recognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
			recognizer.delegate = self
			presentationRoundedCornerView.addGestureRecognizer(recognizer)
			panGestureRecognizer = recognizer
		}
		
		do {
			let dimmingView = UIView(frame: containerView.bounds)
			dimmingView.backgroundColor = .black
			dimmingView.isOpaque = false
			dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped(_:))))
			self.dimmingView = dimmingView
			containerView.addSubview(dimmingView)
			
			dimmingView.alpha = 0
			presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
				dimmingView.alpha = 0.5
			}, completion: nil)
		}
	}
	
	override func presentationTransitionDidEnd(_ completed: Bool) {
		if !completed {
			presentationWrappingView = nil;
			dimmingView = nil;
		}
		else {
			let center = NotificationCenter.default
			center.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
			center.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
			center.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
		}
	}
	
	override func dismissalTransitionWillBegin() {
		presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
			self.dimmingView?.alpha = 0.0
		}, completion: nil)
	}
	
	override func dismissalTransitionDidEnd(_ completed: Bool) {
		if completed {
			presentationWrappingView = nil
			dimmingView = nil
			NotificationCenter.default.removeObserver(self)
		}
	}
	
	override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
		super.preferredContentSizeDidChange(forChildContentContainer: container)
		if (container === presentedViewController) {
			containerView?.setNeedsLayout()
		}
	}
	
	override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
		if (container === presentedViewController) {
			var size = container.preferredContentSize
			size.height = max(size.height, 44)
			return size
		}
		else {
			return size(forChildContentContainer: container, withParentContainerSize: parentSize)
		}
	}
	
	override var frameOfPresentedViewInContainerView: CGRect {
		guard let containerView = self.containerView else {return .zero}
		let containerViewBounds = containerView.bounds
		let presentedViewContentSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerViewBounds.size)
		
		var presentedViewControllerFrame = containerViewBounds
		presentedViewControllerFrame.size.height = presentedViewContentSize.height
		presentedViewControllerFrame.origin.y = containerViewBounds.maxY - presentedViewContentSize.height
		
		presentedViewControllerFrame.origin.y -= keyboardFrame.size.height;
		if (presentedViewControllerFrame.origin.y <= 40) {
			presentedViewControllerFrame.size.height -= 40 - presentedViewControllerFrame.origin.y;
			presentedViewControllerFrame.origin.y = 40;
		}
		
		return presentedViewControllerFrame;
	}
	
	override func containerViewWillLayoutSubviews() {
		super.containerViewWillLayoutSubviews()
		
		if let containerView = self.containerView {
			dimmingView?.frame = containerView.bounds
		}
		presentationWrappingView?.frame = frameOfPresentedViewInContainerView

	}
	
	//MARK: - UIViewControllerAnimatedTransitioning
	
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return transitionContext?.isAnimated == true ? 0.25 : 0.0
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let fromViewController = transitionContext.viewController(forKey: .from) else {return}
		guard let toViewController = transitionContext.viewController(forKey: .to) else {return}
		
		let toView = transitionContext.view(forKey: .to)
		
		let containerView = transitionContext.containerView
		
		let fromView = transitionContext.view(forKey: .from)
		
		let isPresenting = fromViewController === presentingViewController
		
		//let fromViewInitialFrame = transitionContext.initialFrame(for: fromViewController)
		var fromViewFinalFrame = transitionContext.finalFrame(for: fromViewController)
		var toViewInitialFrame = transitionContext.initialFrame(for: toViewController)
		let toViewFinalFrame = transitionContext.finalFrame(for: toViewController)
		
		if let toView = toView {
			containerView.addSubview(toView)
		}
		
		if isPresenting {
			toViewInitialFrame.origin = CGPoint(x: containerView.bounds.minX, y: containerView.bounds.maxY)
			toViewInitialFrame.size = toViewFinalFrame.size
			toView?.frame = toViewInitialFrame;
		}
		else {
			fromViewFinalFrame = fromView!.frame.offsetBy(dx: 0, dy: fromView!.frame.height)
		}
		
		let transitionDuration = self.transitionDuration(using: transitionContext)
		/*UIView.animate(withDuration: transitionDuration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [], animations: {
			if isPresenting {
				toView?.frame = toViewFinalFrame
			}
			else {
				fromView?.frame = fromViewFinalFrame
			}
			
		}) { finished in
			let wasCancelled = transitionContext.transitionWasCancelled
			transitionContext.completeTransition(!wasCancelled)
		}*/
		UIView.animate(withDuration: transitionDuration, delay: 0, options: interactiveTransition == nil ? [.curveEaseOut] : [.curveLinear], animations: {
			if isPresenting {
				toView?.frame = toViewFinalFrame
			}
			else {
				fromView?.frame = fromViewFinalFrame
			}
		}) { _ in
			let wasCancelled = transitionContext.transitionWasCancelled
			transitionContext.completeTransition(!wasCancelled)
		}
	}
	
	//MARK: - UIViewControllerTransitioningDelegate
	
	func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
		assert(presentedViewController === presented)
		return self
	}
	
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return self
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return self
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return interactiveTransition
	}
	
	//MARK: - Notifications
	
	@IBAction private func dimmingViewTapped(_ sender: UITapGestureRecognizer) {
		presentingViewController.dismiss(animated: true, completion: nil)
	}
	
	
	@objc private func keyboardWillShow(_ note: Notification) {
		
	}

	@objc private func keyboardWillHide(_ note: Notification) {
		
	}

	@objc private func keyboardWillChangeFrame(_ note: Notification) {
		
	}
	
	//MARK: - Gesture Recognizer
	
	private var tableView: UITableView?
	
	@objc private func onPan(_ recognizer: UIPanGestureRecognizer) {
		switch recognizer.state {
		case .began:
			tableView = recognizer.view?.hitTest(recognizer.location(in: recognizer.view), with: nil)?.ancestor(of: UITableView.self)
		case .changed:
			//let tableView = self.tableView ?? recognizer.view?.hitTest(recognizer.location(in: recognizer.view), with: nil)?.ancestor(of: UITableView.self)
			
			let t = recognizer.translation(in: containerView!)

			if fabs(t.x) > 10 && fabs(t.x) > t.y {
				recognizer.isEnabled = false
				recognizer.isEnabled = true
			}
			else if t.y > 0 {
				if let interactiveTransition = interactiveTransition {
					if let tableView = self.tableView {
						var offset = tableView.contentOffset
						offset.y = -tableView.contentInset.top
						tableView.setContentOffset(offset, animated: false)
						tableView.panGestureRecognizer.setTranslation(.zero, in: tableView)
					}
					
					interactiveTransition.update(t.y / recognizer.view!.bounds.size.height)
				}
				else {
					if let tableView = tableView, tableView.isTracking, tableView.contentOffset.y > -tableView.contentInset.top {
						recognizer.setTranslation(.zero, in: containerView!)
					}
					else {
						interactiveTransition = UIPercentDrivenInteractiveTransition()
						interactiveTransition?.completionSpeed = 0.5
						interactiveTransition?.completionCurve = .easeOut
						
						presentedViewController.dismiss(animated: true, completion: nil)
					}
				}
			}
			
		case .ended:
			let v = recognizer.velocity(in: recognizer.view)
			let t = recognizer.translation(in: recognizer.view)
			if v.y >= 0 && t.y > 40 {
				interactiveTransition?.finish()
			}
			else {
				interactiveTransition?.cancel()
			}
			interactiveTransition = nil
			tableView = nil
		case .cancelled:
			interactiveTransition?.cancel()
			interactiveTransition = nil
			tableView = nil
		default:
			break
		}
	}
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		let hitTest = gestureRecognizer.view?.hitTest(gestureRecognizer.location(in: gestureRecognizer.view), with: nil)
		return hitTest?.ancestor(of: UIPickerView.self) == nil //&& hitTest?.ancestor(of: UICollectionView.self) == nil
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
	
//	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//		return true
//	}
	
//	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//		return true
//	}
}
