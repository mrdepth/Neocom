//: Playground - noun: a place where people can play

import UIKit

enum RouteKind {
	case push
	case modal
	case adaptive
	case sheet
}

class Route {
	let kind: RouteKind
	let identifier: String?
	let storyboard: UIStoryboard?
	let viewController: UIViewController?
	
	init(kind: RouteKind, storyboard: UIStoryboard? = nil,  identifier: String? = nil, viewController: UIViewController? = nil) {
		self.kind = kind
		self.storyboard = storyboard
		self.identifier = identifier
		self.viewController = viewController
	}
	
	func perform(source: UIViewController, view: UIView? = nil) {
	}
	
	func prepareForSegue(source: UIViewController, destination: UIViewController) {
	}
}

struct Router {
	
	struct Database {
		
		class TypeInfo: Route {
			let int: Int
			
			init(_ int: Int) {
				self.int = int
				super.init(kind: .adaptive, identifier: "NCFittingAreaEffectsViewController")
			}
			
		}
	}
}

class TreeRow {
	private let _route: () -> Route?
	
	lazy var route: Route? = self._route()
	
	init(route: @autoclosure @escaping ()-> Route? = nil) {
		_route = route
	}
	
}

class NCFittingModuleInfoRow: TreeRow {
	lazy var type: Int? = {
		return 0
	}()
	
	init() {
		super.init(route: Router.Database.TypeInfo(self.type!))
	}
	

}
