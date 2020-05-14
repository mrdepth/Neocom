//___FILEHEADER___

import Foundation
import Futures

enum ___FILEBASENAMEASIDENTIFIER___: Assembly {
	typealias View = ___VARIABLE_productName___ViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.<#storyboard#>.instantiateViewController(withIdentifier: "___VARIABLE_productName___ViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}

