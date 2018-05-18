//
//  GDPR.swift
//  Neocom
//
//  Created by Artem Shimanski on 18.05.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import AdSupport
import Alamofire

extension UIStoryboard {
	static let gdpr = UIStoryboard(name: "GDPR", bundle: nil)
}

class GDPR {
	private static var window: UIWindow?
	
	class func requireConsent() -> Future<Bool> {
		return .init(true)
	}
	
	class func requestConsent() -> Future<Bool> {
		guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {return .init(false)}
		let stored = UserDefaults.standard.object(forKey: UserDefaults.Key.NCConsent) as? NSNumber
		
		return DispatchQueue.global(qos: .utility).async { () -> Future<Bool> in
			guard try requireConsent().get() else {return (.init(false))}
			if let stored = stored {
				return .init(stored.boolValue)
			}
			let message = try consentRequestMessage().get()
			
			return DispatchQueue.main.async {
				window = UIWindow(frame: UIScreen.main.bounds)
				window?.windowLevel = UIWindowLevelNormal + 1
				window?.backgroundColor = .clear
				window?.rootViewController = UIViewController()
				window?.rootViewController?.view.backgroundColor = .clear
				window?.makeKeyAndVisible()
				let controller = UIStoryboard.gdpr.instantiateInitialViewController()!
				
				let promise = Promise<Bool>()
				
				if let gdprController = ((controller as? UINavigationController)?.topViewController as? GDPRViewController){
					gdprController.completionHandler = { hasConsent in
						UserDefaults.standard.set(hasConsent, forKey: UserDefaults.Key.NCConsent)
						window?.rootViewController?.dismiss(animated: true, completion: {
							window?.isHidden = true
							window = nil
							try? promise.fulfill(hasConsent)
						})
					}
					gdprController.text = message
				}
				
				window?.rootViewController?.present(controller, animated: true, completion: nil)
				
				return promise.future
			}
		}
	}
	
	private class func consentRequestMessage() -> Future<NSAttributedString> {
		let promise = Promise<NSAttributedString>()
		
		Alamofire.request("https://s3-us-west-1.amazonaws.com/appodeal-ios/docs/GDPRPrivacy.html").responseString { response in
			do {
				switch response.result {
				case let .success(string):
					
					let data = string.replacingOccurrences(of: "%APP_NAME%", with: "Neocom").data(using: .utf8) ?? Data()
					let s = try NSMutableAttributedString(data: data, options: [.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
					s.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: s.length))
					try promise.fulfill(s)
				case let .failure(error):
					try? promise.fail(error)
				}
			}
			catch {
				try? promise.fail(error)
			}
		}
		
		return promise.future
	}
}

class GDPRViewController: UIViewController {
	@IBOutlet weak var textView: UITextView!
	var completionHandler: ((Bool) -> Void)?
	var text: NSAttributedString?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		textView.attributedText = text
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	
	@IBAction func onOk(_ sender: Any) {
		completionHandler?(true)
	}
	
	@IBAction func onCancel(_ sender: Any) {
		completionHandler?(false)
	}
}
