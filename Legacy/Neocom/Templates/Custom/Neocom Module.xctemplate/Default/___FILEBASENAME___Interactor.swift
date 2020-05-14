//___FILEHEADER___

import Foundation

class ___FILEBASENAMEASIDENTIFIER___: Interactor {
	typealias Presenter = ___VARIABLE_productName___Presenter
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func configure() {
	}
}
