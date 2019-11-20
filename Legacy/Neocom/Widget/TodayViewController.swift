//
//  TodayViewController.swift
//  Widget
//
//  Created by Artem Shimanski on 12.01.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import UIKit
import NotificationCenter

let roman = ["0","I","II","III","IV","V"]

class AccountCell: UITableViewCell {
	@IBOutlet weak var characterNameLabel: UILabel!
	@IBOutlet weak var characterImageView: UIImageView!
	@IBOutlet weak var skillLabel: UILabel!
	@IBOutlet weak var trainingTimeLabel: UILabel!
//	@IBOutlet weak var skillQueueLabel: UILabel!
}

class TodayViewController: UITableViewController, NCWidgetProviding {
	/*private var data: WidgetData?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@available(iOSApplicationExtension 10.0, *)
	func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
		tableView.layoutIfNeeded()
		tableView.rowHeight = maxSize.height / 2
	}
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		guard let url = WidgetData.url else {
			completionHandler(.noData)
			return
		}
		
		do {
			data = try JSONDecoder().decode(WidgetData.self, from: Data(contentsOf: url))
			tableView.reloadData()
			tableView.layoutIfNeeded()
			preferredContentSize = tableView.contentSize
			completionHandler(data?.accounts.isEmpty == false ? .newData : .noData)
		}
		catch {
			completionHandler(.noData)
		}
    }
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data?.accounts.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! AccountCell
		guard let account = data?.accounts[indexPath.row] else {return cell}
		
		cell.characterNameLabel.text = account.characterName
		
		if let url = WidgetData.url?.deletingLastPathComponent().appendingPathComponent("\(account.characterID).png"), let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
			cell.characterImageView.image = image
		}
		else {
			cell.characterImageView.image = nil
		}
		
//		let date = Date()
//		if let skill = account.skillQueue.first (where: { $0.finishDate > date }) {
		if let skill = account.skillQueue.last {
//			var s = skill.skillName
//			let level = skill.level.clamped(to: 0...5)
//			if level > 0 {
//				s += " \(roman[level])"
//			}
//			cell.skillLabel.text = s
//			cell.trainingTimeLabel.text = NCTimeIntervalFormatter.localizedString(from: skill.finishDate.timeIntervalSinceNow, precision: .minutes)
			cell.trainingTimeLabel.text = " "
			
			cell.skillLabel.text = String(format: NSLocalizedString("%d skills in queue (%@)", comment: ""), account.skillQueue.count, NCTimeIntervalFormatter.localizedString(from: skill.finishDate.timeIntervalSinceNow, precision: .minutes))
		}
		else {
			cell.skillLabel.text = NSLocalizedString("No skills in training", comment: "")
			cell.trainingTimeLabel.text = " "
//			cell.skillQueueLabel.text = " "
		}
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		guard let account = data?.accounts[indexPath.row] else {return}
		guard let url = URL(string: "nc://account?uuid=\(account.uuid)") else {return}
		extensionContext?.open(url, completionHandler: nil)
	}*/
	
}
