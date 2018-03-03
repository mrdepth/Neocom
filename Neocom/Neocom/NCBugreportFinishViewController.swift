//
//  NCBugreportFinishViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import MessageUI

class NCBugreportFinishViewController: NCTreeViewController {
	var subject: String?
	var attachments: [String: Data]?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.noImage,
							Prototype.NCHeaderTableViewCell.static,
							Prototype.NCHeaderTableViewCell.empty,
							Prototype.NCFooterTableViewCell.default,
							Prototype.NCActionTableViewCell.default,
							Prototype.NCSwitchTableViewCell.default,
							Prototype.NCDefaultTableViewCell.placeholder])
		if navigationItem.leftBarButtonItem != nil {
			navigationItem.rightBarButtonItem = nil
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		
		var sections = [TreeNode]()
		
		var rows = attachments?.keys.sorted().map { i -> TreeNode in
			return DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage, title: i)
		} ?? []

		if rows.isEmpty {
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, title: NSLocalizedString("Nothing", comment: "").uppercased()))
		}
		
		sections.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.static, title: NSLocalizedString("The following data will be attached", comment: "").uppercased(), isExpandable: false, children: rows))
		
		if let characterName = NCAccount.current?.characterName {
			sections.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.static, title: characterName.uppercased(), isExpandable: false, children: [
				NCSwitchRow(title: NSLocalizedString("Attach API Key", comment: ""), value: false, handler: { [weak self] (isOn) in
					self?.attachAccessToken = isOn
				}),
				NCFooterRow(title: NSLocalizedString("If you think that your problem is related to your EVE Account, you can attach your API Key. You can revoke API Key at any time in your EVE account settings.", comment: "")),
				NCActionRow(title: NSLocalizedString("Account Settings", comment: "").uppercased(), route: Router.Custom { (_, _) in
					UIApplication.shared.openURL(NCManageAPIKeysURL)
				})
				]))
		}
		
		sections.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, isExpandable: false, children: [
			NCActionRow(title: NSLocalizedString("Send Bug Report", comment: "").uppercased(), route: Router.Custom { [weak self] (_, _) in
				self?.send()
			})
			]))

		
		treeController?.content = RootNode(sections)
		completionHandler()
	}
	
	private var attachAccessToken: Bool = false
	
	private func send() {
		if MFMailComposeViewController.canSendMail() {
			var attachments = self.attachments ?? [:]
			if attachAccessToken {
				if let token = NCAccount.current?.token, let data = try? JSONEncoder().encode(token) {
					attachments["accessToken.json"] = data
				}
			}
			let displayVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
			let version = Bundle.main.infoDictionary![kCFBundleVersionKey as String] as! String
			let controller = MFMailComposeViewController()
			controller.setToRecipients([NCBugReportEmail])
			controller.setSubject("\(displayVersion): \(subject ?? "Bug Report")")
			controller.setMessageBody("Version: \(displayVersion)(\(version))\nDevice: \(UIDevice.current.model)\n \(UIDevice.current.systemName): \(UIDevice.current.systemVersion)\n", isHTML: false)
			attachments.forEach { (name, data) in
				controller.addAttachmentData(data, mimeType: "application/json", fileName: name)
			}
			controller.mailComposeDelegate = self
			present(controller, animated: true, completion: nil)
		}
		else {
			let controller = UIAlertController(title: NSLocalizedString("Unable to send Bug Report", comment: ""), message: NSLocalizedString("Please, set up an email account on your device.", comment: ""), preferredStyle: .alert)
			controller.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
			present(controller, animated: true, completion: nil)
		}
	}
}

extension NCBugreportFinishViewController: MFMailComposeViewControllerDelegate {
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//		controller.dismissAnimated(true)
		switch result {
		case .cancelled:
			controller.dismiss(animated: true, completion: nil)
		case .failed:
			controller.dismiss(animated: true) { [weak self] in
				guard let error = error else {return}
				self?.present(UIAlertController(error: error), animated: true, completion: nil)
			}
		default:
			presentingViewController?.dismiss(animated: true, completion: nil)
		}
	}
}
