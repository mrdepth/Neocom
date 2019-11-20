//
//  PageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class PageViewController: UIViewController {
	lazy var pageControl: SegmentedPageControl = SegmentedPageControl()
	lazy var scrollView: UIScrollView = UIScrollView()
	
	var viewControllers: [UIViewController]? {
		didSet {
			for controller in oldValue ?? [] {
				controller.removeObserver(self, forKeyPath: "title")
			}
			for controller in viewControllers ?? [] {
				controller.addObserver(self, forKeyPath: "title", options: [], context: nil)
			}
			
			pageControl.titles = viewControllers?.map({$0.title?.uppercased() ?? "-"}) ?? []
			
			if (currentPage == nil || viewControllers?.contains(currentPage!) != true) && viewControllers?.isEmpty == false {
				currentPage = scrollView.bounds.size.width > 0
					? viewControllers![Int((scrollView.contentOffset.x / scrollView.bounds.size.width).rounded()).clamped(to: 0...(viewControllers!.count - 1))]
					: viewControllers?.first
				
				let noParent = currentPage?.parent == nil
				if noParent {
					addChild(viewController: currentPage!)
				}
				
				
				let appearance: Appearance? = isViewLoaded && transitionCoordinator == nil ? Appearance(true, controller: currentPage!) : nil
				
				if currentPage?.view.superview == nil {
					let view = UIView(frame: currentPage!.view.bounds)
					view.backgroundColor = .clear
					view.addSubview(currentPage!.view)
					scrollView.addSubview(view)
				}
				
				appearance?.finish()
				if noParent {
					currentPage?.didMove(toParent: self)
				}
			}
			
			if isViewLoaded {
				view.setNeedsLayout()
			}
		}
	}
	
	var currentPage: UIViewController? {
		didSet {
			guard toolbarItemsOverride == nil else {return}
			setToolbarItems(currentPage?.toolbarItems, animated: true)
		}
	}
	
	private var toolbarItemsOverride: [UIBarButtonItem]?
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		scrollView.canCancelContentTouches = false
		//		scrollView.delaysContentTouches = false
		
		self.toolbarItemsOverride = self.toolbarItems
		
		pageControl.translatesAutoresizingMaskIntoConstraints = false
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(pageControl)
		view.addSubview(scrollView)
		pageControl.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor)
		
		if #available(iOS 11.0, *) {
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:[top]-0-[page]-0-[scrollView]", options: [], metrics: nil, views: ["top": topLayoutGuide, "page": pageControl, "scrollView": scrollView]))
			scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
		}
		else {
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:[top]-0-[page]-0-[scrollView]-0-[bottom]", options: [], metrics: nil, views: ["top": topLayoutGuide, "bottom": bottomLayoutGuide, "page": pageControl, "scrollView": scrollView]))
		}
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[page]-0-|", options: [], metrics: nil, views: ["page": pageControl]))
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[scrollView]-0-|", options: [], metrics: nil, views: ["scrollView": scrollView]))
		pageControl.scrollView = scrollView
		scrollView.delegate = self
		scrollView.isPagingEnabled = true
	}
	
	deinit {
		for controller in viewControllers ?? [] {
			controller.removeObserver(self, forKeyPath: "title")
		}
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "title" {
			pageControl.titles = viewControllers?.map({$0.title?.uppercased() ?? "-"}) ?? []
		}
		else {
			return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let contentSize = CGSize(width: scrollView.bounds.size.width * CGFloat(viewControllers?.count ?? 0), height: scrollView.bounds.size.height)
		
		if scrollView.contentSize != contentSize {
			scrollView.contentSize = CGSize(width: scrollView.bounds.size.width * CGFloat(viewControllers?.count ?? 0), height: scrollView.bounds.size.height)
			for (i, controller) in (viewControllers ?? []).enumerated() {
				if let view = controller.view.superview {
					view.frame = frameForPage(at: i)
					controller.view.frame = view.bounds
				}
			}
			if let currentPage = currentPage, let i = viewControllers?.index(of: currentPage) {
				self.scrollView.contentOffset.x = CGFloat(i) * scrollView.bounds.size.width
			}
			if !scrollView.isDragging && !scrollView.isDecelerating {
				scrollViewDidEndScrolling()
			}
		}
		
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		for controller in viewControllers ?? [] {
			controller.setEditing(editing, animated: animated)
		}
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		scrollViewDidEndScrolling()
	}
	
	//MARK: - UIScrollViewDelegate
	
	
	
	
	//MARK: - Private

	private class Appearance {
		let controller: UIViewController
		let isAppearing: Bool
		
		init(_ isAppearing: Bool, controller: UIViewController) {
			self.isAppearing = isAppearing
			controller.beginAppearanceTransition(isAppearing, animated: false)
			self.controller = controller
		}
		
		private var isFinished: Bool = false
		
		func finish() {
			guard !isFinished else {return}
			controller.endAppearanceTransition()
			isFinished = true
		}
		
		deinit {
			finish()
		}
		
	}
	
	private var appearances: [Appearance] = []
	private var pendingChildren: [UIViewController] = []

	private func addChild(viewController: UIViewController) {
		addChild(viewController)
	}
	
	private func scrollViewDidEndScrolling() {
		let copy = appearances
		for appearance in copy {
			let controller = appearance.controller
			guard let i = viewControllers?.index(of: controller) else {continue}
			
			if frameForPage(at: i).intersects(scrollView.bounds) {
				if !appearance.isAppearing {
					controller.beginAppearanceTransition(true, animated: false)
				}
				currentPage = controller
			}
			else {
				if appearance.isAppearing {
					controller.beginAppearanceTransition(false, animated: false)
				}
				controller.view.superview?.removeFromSuperview()
				controller.view.removeFromSuperview()
			}
		}
		for controller in pendingChildren {
			controller.didMove(toParent: self)
		}
		pendingChildren = []
		appearances = []
	}
	
	private func frameForPage(at index: Int) -> CGRect {
		var frame = scrollView.bounds
		frame.origin.y = 0
		frame.origin.x = frame.size.width * CGFloat(index)
		return frame
	}
}

extension PageViewController: UIScrollViewDelegate {
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		pageControl.setNeedsLayout()
		for (i, controller) in (viewControllers ?? []).enumerated() {
			if appearances.first(where: {$0.controller === controller}) == nil {
				let frame = frameForPage(at: i)
				if frame.intersects(scrollView.bounds) {
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
							controller.view.translatesAutoresizingMaskIntoConstraints = true
							
							let view = UIView(frame: frame)
							controller.view.frame = view.bounds
							view.backgroundColor = .clear
							view.addSubview(controller.view)
							scrollView.addSubview(view)
						}
					}
				}
			}
		}
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		scrollViewDidEndScrolling()
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if !decelerate {
			scrollViewDidEndScrolling()
		}
	}
	
	func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		scrollViewDidEndScrolling()
	}
	
}
