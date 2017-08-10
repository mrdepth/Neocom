//
//  NCFeedItemViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import WebKit
import SafariServices

class NCFeedItemViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
	var item: RSS.Item?
	
	var webView: WKWebView!
	
	override func loadView() {
		let webConfiguration = WKWebViewConfiguration()
		let contentController = WKUserContentController()
		
		var scriptContent = "var meta = document.createElement('meta');"
		scriptContent += "meta.name='viewport';"
		scriptContent += "meta.content='width=device-width';"
		scriptContent += "document.getElementsByTagName('head')[0].appendChild(meta);"

		let script = WKUserScript(source: scriptContent, injectionTime: .atDocumentStart, forMainFrameOnly: true)
		
		contentController.addUserScript(script)
		webConfiguration.userContentController = contentController
		
		webView = WKWebView(frame: .zero, configuration: webConfiguration)
		webView.backgroundColor = UIColor.background
		webView.scrollView.backgroundColor = UIColor.background
//		webView.uiDelegate = self
		webView.navigationDelegate = self
		view = webView
		title = item?.title
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		if item?.link != nil {
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Safari", comment: ""), style: .plain, target: self, action: #selector(onSafari(_:)))
		}
		
		guard let content = item?.summary else {return}
		
		var scriptContent = "var meta = document.createElement('meta');"
		scriptContent += "meta.name='viewport';"
		scriptContent += "meta.content='width=device-width';"
		scriptContent += "document.getElementsByTagName('head')[0].appendChild(meta);"

		
		let html = "<html><head><meta name=\"viewport\" content=\"width=device-width\"><style>a:link{color: \(UIColor.caption.css);};a:visited{color: \(UIColor.lightText.css);}</style></head><body style=\"background-color:\(UIColor.background.css);color:white;\"><h4><a href=\"\(item?.link?.absoluteString ?? "")\">\(item?.title ?? "")</a></h4>\(content)</body></html>"
		webView.loadHTMLString(html, baseURL: item?.link)
	}
	
	@IBAction func onSafari(_ sender: Any) {
		guard let url = item?.link else {return}
		present(SFSafariViewController(url: url), animated: true, completion: nil)
	}
	
	//MARK: - WKNavigationDelegate
	
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		if navigationAction.navigationType == .other {
			decisionHandler(.allow)
		}
		else {
			decisionHandler(.cancel)
			guard let url = navigationAction.request.url else {return}
			present(SFSafariViewController(url: url), animated: true, completion: nil)
		}
		
	}
	
}
