//
//  SheetPresentationController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/20/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

fileprivate let cornerRadius = 16.0 as CGFloat

class SheetPresentationController: UIPresentationController, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
	
	private var dimmingView: UIView?
	private var presentationWrappingView: UIView?
	private var presentationRoundedCornerView: UIView?
	private var presentedViewControllerWrappingView: UIView?
	private var keyboardFrame: CGRect = .zero
	private var interactiveTransition: SlideDownDismissalInteractiveTransitioning?
	private var arrowView: ArrowView?
	var sourceView: UIView?
	var sourceRect: CGRect?
	
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
			
			let presentationRoundedCornerView = UIView(frame: presentationWrappingView.bounds)
			presentationRoundedCornerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			presentationRoundedCornerView.layer.cornerRadius = cornerRadius
			
			presentationRoundedCornerView.layer.masksToBounds = true
			presentationRoundedCornerView.backgroundColor = .background
			
			self.presentationRoundedCornerView = presentationRoundedCornerView
			
			let presentedViewControllerWrapperView = UIView(frame: presentationRoundedCornerView.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: cornerRadius * 2.0, right: 0)))
			presentedViewControllerWrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			self.presentedViewControllerWrappingView = presentedViewControllerWrapperView
			
			presentedViewControllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			presentedViewControllerView.frame = presentedViewControllerWrapperView.bounds
			presentedViewControllerWrapperView.addSubview(presentedViewControllerView)
			
			presentationRoundedCornerView.addSubview(presentedViewControllerWrapperView)
			presentationWrappingView.addSubview(presentationRoundedCornerView)
			
			interactiveTransition = SlideDownDismissalInteractiveTransitioning(viewController: presentedViewController)
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
			center.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
			center.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
			center.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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
	
	var isPopoverStyle: Bool {
		return traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular && sourceView != nil
	}
	
	override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
		if (container === presentedViewController) {
			var size = container.preferredContentSize
			size.height = max(size.height, 44)
			if !isPopoverStyle {
				size.width = min(parentSize.width, parentSize.height)
			}
			return size
		}
		else {
			return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
		}
	}
	
	override var frameOfPresentedViewInContainerView: CGRect {
		guard let containerView = self.containerView else {return .zero}
		let containerViewBounds = containerView.bounds
		let presentedViewContentSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerViewBounds.size)
		
		var presentedViewControllerFrame = containerViewBounds
		presentedViewControllerFrame.size = presentedViewContentSize
		
		if !isPopoverStyle {
			presentedViewControllerFrame.origin.y = containerViewBounds.maxY - presentedViewContentSize.height
			presentedViewControllerFrame.origin.x = (containerViewBounds.maxX - presentedViewContentSize.width) / 2
			presentedViewControllerFrame.size.height += cornerRadius * 2
			
			presentedViewControllerFrame.origin.y -= keyboardFrame.size.height;
			if (presentedViewControllerFrame.origin.y <= 40) {
				presentedViewControllerFrame.size.height -= 40 - presentedViewControllerFrame.origin.y;
				presentedViewControllerFrame.origin.y = 40;
			}
		}
		else {
			assert(sourceView != nil)
			
			let safeArea: CGRect
			if #available(iOS 11.0, *) {
				safeArea = presentingViewController.view.convert(presentingViewController.view.bounds.inset(by: presentingViewController.view.safeAreaInsets), to: containerView)
			} else {
				safeArea = presentingViewController.view.convert(presentingViewController.view.bounds.inset(by: UIEdgeInsets(top: presentingViewController.topLayoutGuide.length, left: 0, bottom: presentingViewController.bottomLayoutGuide.length, right: 0)), to: containerView)
			}
			let sourceRect = sourceView!.convert(sourceView!.bounds, to: containerView)
			
			let arrowHeight = arrowView?.height ?? 0
			
			//Find preffer popover location
			
			let xLeft = sourceRect.minX - presentedViewContentSize.width - arrowHeight
			let xRight = sourceRect.maxX
			
			if xLeft > safeArea.minX {
				presentedViewControllerFrame.origin.x = xLeft
				presentedViewControllerFrame.size.width = presentedViewContentSize.width + arrowHeight
				presentedViewControllerFrame.origin.y = (sourceRect.midY - presentedViewControllerFrame.height / 2).clamped(to: safeArea.minY...min((safeArea.maxY - presentedViewContentSize.height), safeArea.height))
				arrowView?.arrowDirection = .right
			}
			else if xRight + presentedViewContentSize.width + arrowHeight < safeArea.maxX {
				presentedViewControllerFrame.origin.x = xRight
				presentedViewControllerFrame.size.width = presentedViewContentSize.width + arrowHeight
				presentedViewControllerFrame.origin.y = (sourceRect.midY - presentedViewControllerFrame.height / 2).clamped(to: safeArea.minY...min((safeArea.maxY - presentedViewContentSize.height), safeArea.height))
				arrowView?.arrowDirection = .left
			}
			else {
				if safeArea.midY < sourceRect.midY {
					arrowView?.arrowDirection = .down
					presentedViewControllerFrame.origin.y = sourceRect.minY - presentedViewContentSize.height - arrowHeight
				}
				else {
					arrowView?.arrowDirection = .up
					presentedViewControllerFrame.origin.y = sourceRect.maxY
				}
				presentedViewControllerFrame.origin.x = (sourceRect.midX - presentedViewControllerFrame.width / 2).clamped(to: safeArea.minX...min((safeArea.maxX - presentedViewContentSize.width), safeArea.width))
				presentedViewControllerFrame.size.height = presentedViewContentSize.height + arrowHeight
			}
			
			//Reduce height if needed
			if presentedViewControllerFrame.minY < safeArea.minY {
				presentedViewControllerFrame.origin.y = safeArea.minY
				presentedViewControllerFrame.size.height -= safeArea.minY - presentedViewControllerFrame.minY
			}
			if presentedViewControllerFrame.maxY > safeArea.maxY {
				let dh = presentedViewControllerFrame.maxY - safeArea.maxY
				presentedViewControllerFrame.origin.y -= dh
				presentedViewControllerFrame.size.height -= dh
			}
		}
		
		return presentedViewControllerFrame;
	}
	
	private var arrowPosition: CGPoint {
		guard let arrowView = arrowView, let presentationWrappingView = presentationWrappingView, let sourceView = sourceView else {return .zero}
		
		var position = presentationWrappingView.convert(sourceView.center, from: sourceView.superview)
		position.x = position.x.clamped(to: (arrowView.height/2)...(presentationWrappingView.bounds.maxX - arrowView.height / 2))
		position.y = position.y.clamped(to: (arrowView.height/2)...(presentationWrappingView.bounds.maxY - arrowView.height / 2))
		
		return position
	}
	
	override func containerViewWillLayoutSubviews() {
		if isPopoverStyle {
			if arrowView == nil {
				let arrowView = ArrowView(frame: .zero)
				arrowView.sizeToFit()
				presentationWrappingView?.addSubview(arrowView)
				self.arrowView = arrowView
			}
		}
		else if let arrowView = arrowView, !isPopoverStyle {
			arrowView.removeFromSuperview()
			self.arrowView = nil
		}
		
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
			
			if let presentationRoundedCornerView = presentationRoundedCornerView {
				if let arrowView = arrowView {
					self.arrowView?.sizeToFit()
					
					switch arrowView.arrowDirection {
					case .left:
						presentationRoundedCornerView.frame = presentationWrappingView.bounds.inset(by: UIEdgeInsets(top: 0, left: arrowView.height, bottom: 0, right: 0))
					case .right:
						presentationRoundedCornerView.frame = presentationWrappingView.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: arrowView.height))
					case .up:
						presentationRoundedCornerView.frame = presentationWrappingView.bounds.inset(by: UIEdgeInsets(top: arrowView.height, left: 0, bottom: 0, right: 0))
					case .down:
						presentationRoundedCornerView.frame = presentationWrappingView.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: arrowView.height, right: 0))
					}
					
					arrowView.center = arrowPosition
				}
				else {
					presentationRoundedCornerView.frame = presentationWrappingView.bounds
				}
			}
			
			
//			super.presentedView?.frame = presentationWrappingView.bounds
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
		
		let isPopoverStyle = self.isPopoverStyle
		
		if isPopoverStyle {
			if isPresenting {
				toView?.frame = toViewFinalFrame
				toView?.alpha = 0.0
			}
		}
		else {
			if isPresenting {
				toViewInitialFrame.origin =  CGPoint(x: toViewFinalFrame.origin.x, y: containerView.bounds.maxY)
				toViewInitialFrame.size = toViewFinalFrame.size
				toView?.frame = toViewInitialFrame
			}
			else {
				fromViewFinalFrame.origin =  CGPoint(x: fromViewFinalFrame.origin.x, y: containerView.bounds.maxY)
			}
		}
		
		
		let transitionDuration = self.transitionDuration(using: transitionContext)
		UIView.animate(withDuration: transitionDuration, delay: 0, options: interactiveTransition?.isInteractive == true ? [.curveLinear] : [.curveEaseOut], animations: {
			if isPopoverStyle {
				if isPresenting {
					toView?.alpha = 1.0
				}
				else {
					fromView?.alpha = 0.0
				}
			}
			else {
				if isPresenting {
					toView?.frame = toViewFinalFrame
				}
				else {
					fromView?.frame = fromViewFinalFrame
				}
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

class ArrowView: UIView {
	enum ArrowDirection {
		case up
		case down
		case left
		case right
	}
	var arrowDirection = ArrowDirection.up {
		didSet {
			invalidateIntrinsicContentSize()
		}
	}
	
	var width: CGFloat = 25
	var height: CGFloat = 10
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		layer.mask = CAShapeLayer()
		layer.mask?.frame = layer.bounds
		backgroundColor = .white
		(layer.mask as? CAShapeLayer)?.path = path.cgPath
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		layer.mask = CAShapeLayer()
		layer.mask?.frame = layer.bounds
		(layer.mask as? CAShapeLayer)?.path = path.cgPath
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		layer.mask?.frame = layer.bounds
		(layer.mask as? CAShapeLayer)?.path = path.cgPath
	}
	
	var path: UIBezierPath {
		let a: CGFloat = 0.35
		let b: CGFloat = 0.15
		
		let path = UIBezierPath()
		path.move(to: CGPoint(x: -0.5, y: 0))
		path.addCurve(to: CGPoint(x: 0, y: 1), controlPoint1: CGPoint(x: -a, y: 0), controlPoint2: CGPoint(x: -b, y: 1))
		path.addCurve(to: CGPoint(x: 0.5, y: 0), controlPoint1: CGPoint(x: b, y: 1), controlPoint2: CGPoint(x: a, y: 0))
		
		let transform: CGAffineTransform
		
		switch arrowDirection {
		case .up:
			transform = CGAffineTransform(translationX: 0.5, y: 1).scaledBy(x: 1, y: -1)
		case .down:
			transform = CGAffineTransform(translationX: 0.5, y: 0)
		case .left:
			transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2).translatedBy(x: 0.5, y: -1)
		case .right:
			transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2).translatedBy(x: -0.5, y: 0)
		}
		
		path.apply(transform.concatenating(CGAffineTransform(scaleX: bounds.width, y: bounds.height)))
		path.close()
		return path
	}
	
	override var intrinsicContentSize: CGSize {
		switch arrowDirection {
		case .up, .down:
			return CGSize(width: width, height: height)
		case .left, .right:
			return CGSize(width: height, height: width)
		}
	}
	
	override func sizeThatFits(_ size: CGSize) -> CGSize {
		return intrinsicContentSize
	}
}
