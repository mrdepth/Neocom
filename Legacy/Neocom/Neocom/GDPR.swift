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
import Futures

//fileprivate let GDPRCountryCodes = [
//	"BE",	"EL",	"LT",	"PT",
//	"BG",	"ES",	"LU",	"RO",
//	"CZ",	"FR",	"HU",	"SI",
//	"DK",	"HR",	"MT",	"SK",
//	"DE",	"IT",	"NL",	"FI",
//	"EE",	"CY",	"AT",	"SE",
//	"IE",	"LV",	"PL",	"UK",
//	"CH",	"NO",	"IS",	"LI"
//]

//fileprivate let GDPRStartDate: Date = {
//	let dateFormatter = DateFormatter()
//	dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
//	#if DEBUG
//	return dateFormatter.date(from: "2018.05.20 00:00")!
//	#else
//	return dateFormatter.date(from: "2018.05.28 00:00")!
//	#endif
//}()

struct IsEEA: Codable {
	var is_request_in_eea_or_unknown: Bool
}


//struct APIIP: Codable {
//	var country: String
//	var countryCode: String
//}


extension UIStoryboard {
	static let gdpr = UIStoryboard(name: "GDPR", bundle: nil)
}

class GDPR {
	private static var window: UIWindow?
	
	class func requireConsent() -> Future<Bool> {
//		guard Date() >= GDPRStartDate else {return .init(false)}
		let promise = Promise<Bool>()
		Session.default.request("https://adservice.google.com/getconfig/pubvendors?es=2&pubs=ca-app-pub-0434787749004673~8578320061").validate().responseDecodable { (response: DataResponse<IsEEA>) in
			switch response.result {
			case let .success(value):
				#if DEBUG
				try? promise.fulfill(true)
				#else
				try? promise.fulfill(value.is_request_in_eea_or_unknown)
				#endif
			case let .failure(error):
				try? promise.fail(error)
			}
		}
//		Alamofire.request("http://ip-api.com/json").validate().responseJSONDecodable { (response: DataResponse<APIIP>) in
//			switch response.result {
//			case let .success(value):
//				try? promise.fulfill(GDPRCountryCodes.contains(value.countryCode.uppercased()))
//			case let .failure(error):
//				try? promise.fail(error)
//			}
//		}
		
		return promise.future
	}
	
	class func requestConsent() -> Future<Bool> {
		guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {return .init(false)}
		let stored = UserDefaults.standard.object(forKey: UserDefaults.Key.NCConsent) as? NSNumber
		
		return DispatchQueue.global(qos: .utility).async { () -> Future<Bool> in
			guard try requireConsent().get() else {return (.init(true))}
			#if DEBUG
			#else
			if let stored = stored {
				return .init(stored.boolValue)
			}
			#endif
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
        Session.default.request("https://s3-us-west-1.amazonaws.com/appodeal-ios/docs/GDPRPrivacy.html").validate().responseString { response in
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

extension GDPRViewController: UITextViewDelegate {

	func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
		if UIApplication.shared.canOpenURL(URL) {
			UIApplication.shared.openURL(URL)
		}
		return false
	}

}
