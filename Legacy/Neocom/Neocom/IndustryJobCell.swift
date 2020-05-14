//
//  IndustryJobCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/9/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import TreeController

class IndustryJobCell: RowCell {
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
	enum IndustryJobCell {
		static let `default` = Prototype(nib: UINib(nibName: "IndustryJobCell", bundle: nil), reuseIdentifier: "IndustryJobCell")
	}
}

extension Tree.Item {
	class IndustryJobRow: RoutableRow<ESI.Industry.Job> {
		override var prototype: Prototype? {
			return Prototype.IndustryJobCell.default
		}
		
		let location: EVELocation?
		lazy var type: SDEInvType? = Services.sde.viewContext.invType(content.blueprintTypeID)
		lazy var activity: SDERamActivity? = Services.sde.viewContext.ramActivity(content.activityID)
		
		init(_ content: ESI.Industry.Job, location: EVELocation?) {
			self.location = location
			super.init(content, route: Router.SDE.invTypeInfo(.typeID(content.blueprintTypeID)))
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? IndustryJobCell else {return}
			cell.titleLabel.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
			cell.subtitleLabel.attributedText = (location ?? .unknown).displayName
			cell.iconView.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
			

			let activity = self.activity?.activityName ?? NSLocalizedString("Unknown Activity", comment: "")
			let t = content.endDate.timeIntervalSinceNow
			
			let status = content.currentStatus
			
			let s: String
			switch status {
			case .active:
				cell.progressView.progress = 1.0 - Float(t / TimeInterval(content.duration))
				s = "\(TimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes)) (\(Int(cell.progressView.progress * 100))%)"
			case .cancelled:
				s = "\(NSLocalizedString("cancelled", comment: "")) \(DateFormatter.localizedString(from: content.endDate, dateStyle: .short, timeStyle: .short))"
				cell.progressView.progress = 0
			case .delivered:
				s = "\(NSLocalizedString("delivered", comment: "")) \(DateFormatter.localizedString(from: content.endDate, dateStyle: .short, timeStyle: .short))"
				cell.progressView.progress = 1
			case .paused:
				s = "\(NSLocalizedString("paused", comment: "")) \(DateFormatter.localizedString(from: content.endDate, dateStyle: .short, timeStyle: .short))"
				cell.progressView.progress = 0
			case .ready:
				s = "\(NSLocalizedString("ready", comment: "")) \(DateFormatter.localizedString(from: content.endDate, dateStyle: .short, timeStyle: .short))"
				cell.progressView.progress = 1
			case .reverted:
				s = "\(NSLocalizedString("reverted", comment: "")) \(DateFormatter.localizedString(from: content.endDate, dateStyle: .short, timeStyle: .short))"
				cell.progressView.progress = 0
			}
			
			cell.stateLabel.attributedText = "\(activity): " * [NSAttributedString.Key.foregroundColor: UIColor.white] + s * [NSAttributedString.Key.foregroundColor: UIColor.lightText]
			
			cell.jobRunsLabel.text = UnitFormatter.localizedString(from: content.runs, unit: .none, style: .long)
			cell.runsPerCopyLabel.text = UnitFormatter.localizedString(from: content.licensedRuns ?? 0, unit: .none, style: .long)
			
			let color = status == .active || status == .ready ? UIColor.white : UIColor.lightText
			cell.titleLabel.textColor = color
			cell.jobRunsLabel.textColor = color
			cell.runsPerCopyLabel.textColor = color
		}
	}
}

