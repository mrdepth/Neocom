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
	@IBOutlet weak var jobRunsLabel: UILabel!
	@IBOutlet weak var runsPerCopyLabel: UILabel!
	
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

protocol NCIndustryJob {
	var activityID: Int {get}
//	public var blueprintID: Int64
//	public var blueprintLocationID: Int64
	var blueprintTypeID: Int {get}
//	public var completedCharacterID: Int?
//	public var completedDate: Date?
//	public var cost: Double?
	var duration: Int {get}
	var endDate: Date {get}
//	public var facilityID: Int64
//	public var installerID: Int
//	public var jobID: Int
	var licensedRuns: Int? {get}
//	public var outputLocationID: Int64
//	public var pauseDate: Date?
//	public var probability: Float?
//	public var productTypeID: Int?
	var runs: Int {get}
	var hashValue: Int {get}
//	public var startDate: Date
//	var stationID: Int64 {get}
	var status: ESI.Industry.JobStatus {get}
	var locationID: Int64 {get}
//	public var successfulRuns: Int?
}

extension NCIndustryJob {
	var currentStatus: ESI.Industry.JobStatus {
		switch status {
		case .active:
			return endDate < Date() ? .ready : status
		default:
			return status
		}
	}
	
}

extension ESI.Industry.Job: NCIndustryJob {
	var locationID: Int64 {
		return stationID
	}
}

extension ESI.Industry.CorpJob: NCIndustryJob {
}

class NCIndustryRow: TreeRow {
	let job: NCIndustryJob
	let location: NCLocation?
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.job.blueprintTypeID]
	}()
	
	lazy var activity: NCDBRamActivity? = {
		return NCDatabase.sharedDatabase?.ramActivities[self.job.activityID]
	}()
	
	init(job: NCIndustryJob, location: NCLocation?) {
		self.job = job
		self.location = location
//		expired = order.issued + TimeInterval(order.duration * 3600 * 24)
		
		super.init(prototype: Prototype.NCIndustryTableViewCell.default, route: Router.Database.TypeInfo(job.blueprintTypeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCIndustryTableViewCell else {return}
		cell.titleLabel.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		cell.subtitleLabel.attributedText = location?.displayName ?? NSLocalizedString("Unknown Location", comment: "") * [NSAttributedStringKey.foregroundColor: UIColor.lightText]
		cell.iconView.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		
		let activity = self.activity?.activityName ?? NSLocalizedString("Unknown Activity", comment: "")
		let t = job.endDate.timeIntervalSinceNow
		
		let status = job.currentStatus
		
		let s: String
		switch status {
		case .active:
			cell.progressView.progress = 1.0 - Float(t / TimeInterval(job.duration))
			s = "\(NCTimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes)) (\(Int(cell.progressView.progress * 100))%)"
		case .cancelled:
			s = "\(NSLocalizedString("cancelled", comment: "")) \(DateFormatter.localizedString(from: job.endDate, dateStyle: .short, timeStyle: .short))"
			cell.progressView.progress = 0
		case .delivered:
			s = "\(NSLocalizedString("delivered", comment: "")) \(DateFormatter.localizedString(from: job.endDate, dateStyle: .short, timeStyle: .short))"
			cell.progressView.progress = 1
		case .paused:
			s = "\(NSLocalizedString("paused", comment: "")) \(DateFormatter.localizedString(from: job.endDate, dateStyle: .short, timeStyle: .short))"
			cell.progressView.progress = 0
		case .ready:
			s = "\(NSLocalizedString("ready", comment: "")) \(DateFormatter.localizedString(from: job.endDate, dateStyle: .short, timeStyle: .short))"
			cell.progressView.progress = 1
		case .reverted:
			s = "\(NSLocalizedString("reverted", comment: "")) \(DateFormatter.localizedString(from: job.endDate, dateStyle: .short, timeStyle: .short))"
			cell.progressView.progress = 0
		}
		cell.stateLabel.attributedText = "\(activity): " * [NSAttributedStringKey.foregroundColor: UIColor.white] + s * [NSAttributedStringKey.foregroundColor: UIColor.lightText]
		
		cell.jobRunsLabel.text = NCUnitFormatter.localizedString(from: job.runs, unit: .none, style: .full)
		cell.runsPerCopyLabel.text = NCUnitFormatter.localizedString(from: job.licensedRuns ?? 0, unit: .none, style: .full)
		
		let color = status == .active || status == .ready ? UIColor.white : UIColor.lightText
		cell.titleLabel.textColor = color
		cell.jobRunsLabel.textColor = color
		cell.runsPerCopyLabel.textColor = color
	}
	
	override lazy var hashValue: Int = job.hashValue
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCIndustryRow)?.hashValue == hashValue
	}

}

