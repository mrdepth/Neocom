//___FILEHEADER___

import Foundation
import CloudData

class ___FILEBASENAMEASIDENTIFIER___: Presenter {
	typealias View = ___VARIABLE_productName___ViewController
	typealias Interactor = ___VARIABLE_productName___Interactor
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
}
