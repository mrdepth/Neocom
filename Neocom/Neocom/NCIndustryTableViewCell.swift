//
//  NCIndustryTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCIndustryTableViewCell: NCTableViewCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var stateLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		let layer = self.progressView.superview?.layer;
		layer?.borderColor = UIColor(number: 0x3d5866ff).cgColor
		layer?.borderWidth = 1.0 / UIScreen.main.scale
	}
}

extension Prototype {
	enum NCIndustryTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCIndustryTableViewCell")
	}
}

class NCIndustryRow: TreeRow {
	let job: ESI.Industry.Job
	let location: NCLocation?
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.job.blueprintTypeID]
	}()
	
	lazy var activity: NCDBRamActivity? = {
		return NCDatabase.sharedDatabase?.ramActivities[self.job.activityID]
	}()
	
	init(job: ESI.Industry.Job, location: NCLocation?) {
		self.job = job
		self.location = location
//		expired = order.issued + TimeInterval(order.duration * 3600 * 24)
		
		super.init(prototype: Prototype.NCIndustryTableViewCell.default, route: Router.Database.TypeInfo(job.blueprintTypeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCIndustryTableViewCell else {return}
		cell.titleLabel.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		cell.subtitleLabel.attributedText = location?.displayName ?? NSLocalizedString("Unknown Location", comment: "") * [NSForegroundColorAttributeName: UIColor.lightText]
		cell.iconView.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		
		let activity = self.activity?.activityName ?? NSLocalizedString("Unknown Activity", comment: "")
		let t = job.endDate.timeIntervalSinceNow

		switch job.status {
		case .active:
			cell.progressView.progress = 1.0 - Float(t / TimeInterval(job.duration))
			cell.stateLabel.text = "\(activity): \(NCTimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes)) (\(Int(cell.progressView.progress * 100))%)"
		case .cancelled:
			cell.stateLabel.text = "\(activity): \(NSLocalizedString("cancelled", comment: "")) \(DateFormatter.localizedString(from: job.endDate, dateStyle: .short, timeStyle: .short))"
			cell.progressView.progress = 0
		case .delivered:
			cell.stateLabel.text = "\(activity): \(NSLocalizedString("delivered", comment: "")) \(DateFormatter.localizedString(from: job.endDate, dateStyle: .short, timeStyle: .short))"
			cell.progressView.progress = 1
		case .paused:
			cell.stateLabel.text = "\(activity): \(NSLocalizedString("paused", comment: "")) \(DateFormatter.localizedString(from: job.endDate, dateStyle: .short, timeStyle: .short))"
			cell.progressView.progress = 0
		case .ready:
			cell.stateLabel.text = "\(activity): \(NSLocalizedString("ready", comment: "")) \(DateFormatter.localizedString(from: job.endDate, dateStyle: .short, timeStyle: .short))"
			cell.progressView.progress = 1
		case .reverted:
			cell.stateLabel.text = "\(activity): \(NSLocalizedString("reverted", comment: "")) \(DateFormatter.localizedString(from: job.endDate, dateStyle: .short, timeStyle: .short))"
			cell.progressView.progress = 0
		}
		
/*		cell.priceLabel.text = NCUnitFormatter.localizedString(from: order.price, unit: .isk, style: .full)
		cell.qtyLabel.text = NCUnitFormatter.localizedString(from: order.volumeRemain, unit: .none, style: .full) + "/" + NCUnitFormatter.localizedString(from: order.volumeTotal, unit: .none, style: .full)
		cell.issuedLabel.text = DateFormatter.localizedString(from: order.issued, dateStyle: .medium, timeStyle: .medium)
		
		let color = order.state == .open ? UIColor.white : UIColor.lightText
		cell.titleLabel.textColor = color
		cell.priceLabel.textColor = color
		cell.qtyLabel.textColor = color
		cell.issuedLabel.textColor = color
		cell.timeLeftLabel.textColor = color
		
		switch order.state {
		case .open:
			cell.stateLabel.text = NSLocalizedString("Open", comment: "")
			let t = expired.timeIntervalSinceNow
			cell.timeLeftLabel.text =  String(format: NSLocalizedString("Expired in %@", comment: ""), NCTimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes))
		case .cancelled:
			cell.stateLabel.text = NSLocalizedString("Cancelled", comment: "")
			cell.timeLeftLabel.text = DateFormatter.localizedString(from: expired, dateStyle: .medium, timeStyle: .medium)
		case .characterDeleted:
			cell.stateLabel.text = NSLocalizedString("Deleted", comment: "")
			cell.timeLeftLabel.text = DateFormatter.localizedString(from: expired, dateStyle: .medium, timeStyle: .medium)
		case .closed:
			cell.stateLabel.text = NSLocalizedString("Closed", comment: "")
			cell.timeLeftLabel.text = DateFormatter.localizedString(from: expired, dateStyle: .medium, timeStyle: .medium)
		case .expired:
			cell.stateLabel.text = NSLocalizedString("Expired", comment: "")
			cell.timeLeftLabel.text = DateFormatter.localizedString(from: expired, dateStyle: .medium, timeStyle: .medium)
		case .pending:
			cell.stateLabel.text = NSLocalizedString("Pending", comment: "")
			cell.timeLeftLabel.text = " "
		}*/
	}
	
	override var hashValue: Int {
		return job.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCIndustryRow)?.hashValue == hashValue
	}

}

