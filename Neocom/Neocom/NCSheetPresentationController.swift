//
//  NCSheetPresentationController.swift
//  Neocom
//
//  Created by Artem Shimanski on 31.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

fileprivate let cornerRadius = 16.0 as CGFloat

class NCSheetPresentationController: UIPresentationController, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {

	private var dimmingView: UIView?
	private var presentationWrappingView: UIView?
	private var presentedViewControllerWrappingView: UIView?
	private var keyboardFrame: CGRect = .zero
	private var interactiveTransition: NCSlideDownDismissalInteractiveTransitioning?

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
			let presentationWrappingView = UIView(frame: frameOfPresentedViewInContainerView)
			presentationWrappingView.layer.shadowOpacity = 0.44
			presentationWrappingView.layer.shadowRadius = 13.0
			presentationWrappingView.layer.shadowOffset = CGSize(width: 0, height: -6)
			self.presentationWrappingView = presentationWrappingView
			
			let presentationRoundedCornerView = UIView(frame: UIEdgeInsetsInsetRect(presentationWrappingView.bounds, UIEdgeInsets(top: 0, left: 0, bottom: -cornerRadius * 2.0, right: 0)))
			presentationRoundedCornerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			presentationRoundedCornerView.layer.cornerRadius = cornerRadius
			presentationRoundedCornerView.layer.masksToBounds = true
			presentationRoundedCornerView.backgroundColor = .background
			
			let presentedViewControllerWrapperView = UIView(frame: UIEdgeInsetsInsetRect(presentationRoundedCornerView.bounds, UIEdgeInsets(top: 0, left: 0, bottom: cornerRadius * 2.0, right: 0)))
			presentedViewControllerWrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			self.presentedViewControllerWrappingView = presentedViewControllerWrapperView
			
			presentedViewControllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			presentedViewControllerView.frame = presentedViewControllerWrapperView.bounds
			presentedViewControllerWrapperView.addSubview(presentedViewControllerView)
			
			presentationRoundedCornerView.addSubview(presentedViewControllerWrapperView)
			presentationWrappingView.addSubview(presentationRoundedCornerView)
			
			interactiveTransition = NCSlideDownDismissalInteractiveTransitioning(viewController: presentedViewController)
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
			size.width = size.width.clamped(to: 0...min(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
//			size.width = min(size.width, min(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
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
		presentedViewControllerFrame.size = presentedViewContentSize
		presentedViewControllerFrame.origin.y = containerViewBounds.maxY - presentedViewContentSize.height
		presentedViewControllerFrame.origin.x = (containerViewBounds.maxX - presentedViewContentSize.width) / 2
		
		presentedViewControllerFrame.origin.y -= keyboardFrame.size.height;
		if (presentedViewControllerFrame.origin.y <= 40) {
			presentedViewControllerFrame.size.height -= 40 - presentedViewControllerFrame.origin.y;
			presentedViewControllerFrame.origin.y = 40;
		}
		
		return presentedViewControllerFrame;
	}
	
	override func containerViewWillLayoutSubviews() {
		if let view = super.presentedView, let presentedViewControllerWrappingView = presentedViewControllerWrappingView, view.superview != presentedViewControllerWrappingView {
			presentedViewControllerWrappingView.addSubview(view)
			view.frame = presentedViewControllerWrappingView.bounds
		}
		super.containerViewWillLayoutSubviews()
		
		if let containerView = self.containerView {
			dimmingView?.frame = containerView.bounds
		}
		if let presentationWrappingView = presentationWrappingView {
			presentationWrappingView.frame = frameOfPresentedViewInContainerView
			super.presentedView?.frame = presentationWrappingView.bounds
		}
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
			toViewInitialFrame.origin =  CGPoint(x: toViewFinalFrame.origin.x, y: containerView.bounds.maxY)
			toViewInitialFrame.size = toViewFinalFrame.size
			toView?.frame = toViewInitialFrame;
		}
		else {
			fromViewFinalFrame = fromView!.frame.offsetBy(dx: 0, dy: fromView!.frame.height)
		}
		
		let transitionDuration = self.transitionDuration(using: transitionContext)
		UIView.animate(withDuration: transitionDuration, delay: 0, options: interactiveTransition?.isInteractive == true ? [.curveLinear] : [.curveEaseOut], animations: {
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
		return interactiveTransition?.isInteractive == true ? interactiveTransition : nil
	}
	
	//MARK: - Notifications
	
	@objc private func keyboardWillShow(_ note: Notification) {
		
	}

	@objc private func keyboardWillHide(_ note: Notification) {
		
	}

	@objc private func keyboardWillChangeFrame(_ note: Notification) {
		
	}

	@IBAction private func dimmingViewTapped(_ sender: UITapGestureRecognizer) {
		presentingViewController.dismiss(animated: true, completion: nil)
	}

}
