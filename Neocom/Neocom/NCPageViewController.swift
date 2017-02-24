//
//  NCPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCPageViewController: UIViewController, UIScrollViewDelegate {
	lazy var pageControl: NCSegmentedPageControl = NCSegmentedPageControl()
	lazy var scrollView: UIScrollView = UIScrollView()
	
	var viewControllers: [UIViewController]? {
		didSet {
			pageControl.titles = viewControllers?.map({$0.title?.uppercased() ?? "-"}) ?? []
			self.view.setNeedsLayout()
			scrollView.contentOffset = .zero
			
			currentPage = viewControllers?.first
			if let currentPage = currentPage {
				addChild(viewController: currentPage)
				scrollView.addSubview(currentPage.view)
				currentPage.didMove(toParentViewController: self)
			}
		}
	}
	
	var currentPage: UIViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		pageControl.translatesAutoresizingMaskIntoConstraints = false
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(pageControl)
		view.addSubview(scrollView)
		pageControl.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor)
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:[top]-0-[page]-0-[scrollView]-0-|", options: [], metrics: nil, views: ["top": topLayoutGuide, "page": pageControl, "scrollView": scrollView]))
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[page]-0-|", options: [], metrics: nil, views: ["page": pageControl]))
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[scrollView]-0-|", options: [], metrics: nil, views: ["scrollView": scrollView]))
		pageControl.scrollView = scrollView
		scrollView.delegate = self
		scrollView.isPagingEnabled = true
		
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		scrollView.contentSize = CGSize(width: scrollView.bounds.size.width * CGFloat(viewControllers?.count ?? 0), height: scrollView.bounds.size.height)
		var rect = scrollView.bounds
		rect.origin = .zero
		for controller in viewControllers ?? [] {
			controller.view.frame = rect
			rect.origin.x += rect.size.width
		}
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		for controller in viewControllers ?? [] {
			controller.setEditing(editing, animated: animated)
		}
	}
	
	//MARK: - UIScrollViewDelegate
	
	private class Appearance {
		let controller: UIViewController
		let isAppearing: Bool
		
		init(_ isAppearing: Bool, controller: UIViewController) {
			self.isAppearing = isAppearing
			controller.beginAppearanceTransition(isAppearing, animated: false)
			self.controller = controller
		}
		
		deinit {
			self.controller.endAppearanceTransition()
		}
		
	}
	
	private var appearances: [Appearance] = []
	private var pendingChildren: [UIViewController] = []
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		pageControl.setNeedsLayout()
		for controller in viewControllers ?? [] {
			if appearances.first(where: {$0.controller === controller}) == nil {
				if controller.view.frame.intersects(scrollView.bounds) {
					if controller == currentPage {
						appearances.append(Appearance(false, controller: controller))
					}
					else {
						if controller.parent == nil {
							addChild(viewController: controller)
							pendingChildren.append(controller)
						}

						appearances.append(Appearance(true, controller: controller))
						
						if controller.view.superview == nil {
							scrollView.addSubview(controller.view)
						}
					}
				}
			}
		}
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		let copy = appearances
		for appearance in copy {
			let controller = appearance.controller
			if controller.view.frame.intersects(scrollView.bounds) {
				if !appearance.isAppearing {
					controller.beginAppearanceTransition(true, animated: false)
//					appearances.append(Appearance(true, controller: controller))
				}
				currentPage = controller
			}
			else {
				if appearance.isAppearing {
					controller.beginAppearanceTransition(false, animated: false)
//					appearances.append(Appearance(false, controller: controller))
				}
				controller.view.removeFromSuperview()
			}
		}
		for controller in pendingChildren {
			controller.didMove(toParentViewController: self)
		}
		pendingChildren = []
		appearances = []
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if !decelerate {
			scrollViewDidEndDecelerating(scrollView)
		}
	}
	
	//MARK: - Private
	
	private func addChild(viewController: UIViewController) {
		addChildViewController(viewController)
		
	}
	
	
}
