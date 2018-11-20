//
//  Route.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum RouteKind {
	case push
	case modal
	case adaptivePush
	case adaptiveModal
	case sheet
	case popover
	case detail
//	case embed(in: UIView)
}

protocol Routing {
	func perform<T: View>(from view: T, sender: Any?, kind: RouteKind?) -> Future<Bool> where T: UIViewController
}

extension Routing {
	func perform<T: View>(from view: T, sender: Any?) -> Future<Bool> where T: UIViewController {
		return perform(from: view, sender: sender, kind: nil)
	}
	
	func perform<T: View>(from view: T) -> Future<Bool> where T: UIViewController {
		return perform(from: view, sender: nil, kind: nil)
	}

}

struct Route<Assembly: Neocom.Assembly>: Routing where Assembly.View: UIViewController {
	var assembly: Assembly
	var input: Assembly.View.Input
	var kind: RouteKind
	
	init(assembly: Assembly, input: Assembly.View.Input, kind: RouteKind) {
		self.assembly = assembly
		self.input = input
		self.kind = kind
	}
	
	@discardableResult
	func perform<T: View>(from view: T, sender: Any? = nil, kind: RouteKind? = nil) -> Future<Bool> where T: UIViewController {
		let kind = kind ?? self.kind
		return assembly.instantiate(input).then(on: .main) { destination -> Future<Bool> in
			let promise = Promise<Bool>()
			destination.unwinder = ViewControllerUnwinder(kind: kind, source: view)
			
			switch kind {
			case .push:
				let navigationController = view.parent is UISearchController ?
					view.presentingViewController?.navigationController :
					((view as? UINavigationController) ?? view.navigationController)
				
				if let navigationController = navigationController {
					let delegate = NavigationControllerDelegate(navigationController)
					delegate.handler = {
						delegate.invalidate()
						try! promise.fulfill(true)
					}
					view.prepareToRoute(to: destination)
					navigationController.pushViewController(destination, animated: true)
				}
				else {
					try! promise.fulfill(false)
				}
			case .modal:
				destination.modalPresentationStyle = .pageSheet
				view.prepareToRoute(to: destination)
				view.present(destination, animated: true) {
					try! promise.fulfill(true)
				}
			case .adaptiveModal:
				let dst = destination as? UINavigationController ?? NavigationController(rootViewController: destination)
				dst.modalPresentationStyle = .custom

				
				if let firstVC = dst.viewControllers.first, firstVC.navigationItem.leftBarButtonItem == nil {
					firstVC.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: .plain, target: firstVC, action: #selector(UIViewController.dismissAnimated(_:)))
				}
				SlideDownDismissalInteractiveTransitioning.add(to: dst)
				
				view.prepareToRoute(to: destination)
				view.present(dst, animated: true) {
					try! promise.fulfill(true)
				}
			case .detail:
				let dst = destination as? UINavigationController ?? NavigationController(rootViewController: destination)
				view.showDetailViewController(dst, sender: sender)
				try! promise.fulfill(true)
			case .sheet:
				let dst = destination as? UINavigationController ?? NavigationController(rootViewController: destination)
				dst.modalPresentationStyle = .custom
				let presentationController = SheetPresentationController(presentedViewController: dst, presenting: view)
//				dst.preferredContentSize = dst.viewControllers[0].preferredContentSize
				withExtendedLifetime(presentationController) {
					dst.transitioningDelegate = presentationController
					view.present(dst, animated: true) {
						try! promise.fulfill(true)
					}
				}

			default:
				try! promise.fulfill(false)
			}
			
			
			return promise.future
		}
	}
}

extension Route  where Assembly.View.Input == Void {
	init(assembly: Assembly, kind: RouteKind) {
		self.assembly = assembly
		self.kind = kind
	}
	
}

protocol Unwinder {
	var kind: RouteKind {get}
	var previous: Unwinder? {get}
	@discardableResult func unwind() -> Future<Bool>
	@discardableResult func unwind<T: View>(to view: T) -> Future<Bool>
	func canPerformUnwind<T: View>(to view: T) -> Bool
}

fileprivate struct ViewControllerUnwinder<Source: View>: Unwinder where Source: UIViewController {
	var kind: RouteKind
	var previous: Unwinder? {
		return source?.unwinder
	}
	
	weak var source: Source?
	
	@discardableResult func unwind() -> Future<Bool> {
		guard let source = source else {return .init(false)}
		
		
		switch kind {
		case .push, .adaptivePush:
			let promise = Promise<Bool>()
			
			let presented = sequence(first: source, next: {$0.parent}).first(where: {$0.presentedViewController != nil})
			if let presented = presented {
				presented.dismiss(animated: true) {
					try! promise.fulfill(true)
				}
				source.navigationController?.popToViewController(source, animated: true)
			}
			else if let navigationController = source.navigationController, navigationController.popToViewController(source, animated: true)?.isEmpty == false {
				
				let delegate = NavigationControllerDelegate(navigationController)
				delegate.handler = {
					delegate.invalidate()
					try! promise.fulfill(true)
				}
			}
			else {
				try! promise.fulfill(false)
			}
			return promise.future
		case .modal, .adaptiveModal, .sheet, .popover:
			let presented = sequence(first: source, next: {$0.parent}).first(where: {$0.presentedViewController != nil})
			if let presented = presented {
				let promise = Promise<Bool>()
				presented.dismiss(animated: true) {
					try! promise.fulfill(true)
				}
				return promise.future
			}
			else {
				return .init(false)
			}
		default:
			return .init(false)
		}
	}
	
	@discardableResult func unwind<T: View>(to view: T) -> Future<Bool> {
		return sequence(first: self as Unwinder, next: {$0.previous}).first(where: {$0.canPerformUnwind(to: view)})?.unwind() ?? .init(false)
	}
	
	func canPerformUnwind<T: View>(to view: T) -> Bool {
		return (view as? Source) === source
	}
	
}

class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
	var handler: (() -> Void)?
	var oldDelegate: UINavigationControllerDelegate?
	weak var navigationController: UINavigationController?
	
	init(_ navigationController: UINavigationController) {
		self.navigationController = navigationController
		oldDelegate = navigationController.delegate
		super.init()
		navigationController.delegate = self
	}
	
	func invalidate() {
		navigationController?.delegate = oldDelegate
	}
	
	deinit {
		if navigationController?.delegate === self {
			navigationController?.delegate = oldDelegate
		}
	}
	
	func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		oldDelegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
	}
	
	func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
		oldDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
		
		DispatchQueue.main.async {
			self.handler?()
		}
	}
	
	override func responds(to aSelector: Selector!) -> Bool {
		return oldDelegate?.responds(to: aSelector) ?? (aSelector == #selector(navigationController(_:didShow:animated:)))
	}
	
	func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
		assert(oldDelegate?.navigationControllerSupportedInterfaceOrientations != nil)
		return oldDelegate?.navigationControllerSupportedInterfaceOrientations?(navigationController) ?? []
	}
	
	func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
		assert(oldDelegate?.navigationControllerPreferredInterfaceOrientationForPresentation != nil)
		return oldDelegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(navigationController) ?? .portrait
	}
	
	
	func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return oldDelegate?.navigationController?(navigationController, interactionControllerFor: animationController)
	}
	
	
	func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return oldDelegate?.navigationController?(navigationController, animationControllerFor: operation, from: fromVC, to: toVC)
	}
}

//struct CustomRoute: Routing {
//	var block: (UIViewController, Any?) -> Future<Bool>
//	
//	init(_ block: @escaping (UIViewController, Any?) -> Future<Bool>) {
//		self.block = block
//	}
//	
//	
//	@discardableResult
//	func perform<T: View>(from view: T, sender: Any? = nil, kind: RouteKind? = nil) -> Future<Bool> where T: UIViewController {
//		return block(view, sender)
//	}
//}
//
