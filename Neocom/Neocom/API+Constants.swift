//
//  API+Constants.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

extension ESI.Incursions.Incursion.State {
	var title: String {
		switch self {
		case .established:
			return NSLocalizedString("Established", comment: "")
		case .mobilizing:
			return NSLocalizedString("Mobilizing", comment: "")
		case .withdrawing:
			return NSLocalizedString("Withdrawing", comment: "")
		}
	}
	
}

extension ESI.Industry.Job {
	var currentStatus: ESI.Industry.JobStatus {
		switch status {
		case .active:
			return endDate < Date() ? .ready : status
		default:
			return status
		}
	}
	
}

extension ESI.Contracts.Contract.ContractType {
	var title: String {
		switch self {
		case .auction:
			return NSLocalizedString("Auction", comment: "")
		case .courier:
			return NSLocalizedString("Courier", comment: "")
		case .itemExchange:
			return NSLocalizedString("Item Exchange", comment: "")
		case .loan:
			return NSLocalizedString("Loan", comment: "")
		case .unknown:
			return NSLocalizedString("Unknown", comment: "")
		}
	}
}

extension ESI.Contracts.Contract.Availability {
	var title: String {
		switch self {
		case .alliance:
			return NSLocalizedString("Alliance", comment: "")
		case .corporation:
			return NSLocalizedString("Corporation", comment: "")
		case .personal:
			return NSLocalizedString("Personal", comment: "")
		case .public:
			return NSLocalizedString("Public", comment: "")
		}
	}
}

extension ESI.Contracts.Contract.Status {
	var title: String {
		switch self {
		case .outstanding:
			return NSLocalizedString("Outstanding", comment: "")
		case .inProgress:
			return NSLocalizedString("In Progress", comment: "")
		case .cancelled:
			return NSLocalizedString("Cancelled", comment: "")
		case .deleted:
			return NSLocalizedString("Deleted", comment: "")
		case .failed:
			return NSLocalizedString("Failed", comment: "")
		case .finished, .finishedContractor, .finishedIssuer:
			return NSLocalizedString("Finished", comment: "")
		case .rejected:
			return NSLocalizedString("Rejected", comment: "")
		case .reversed:
			return NSLocalizedString("Reversed", comment: "")
		}
	}
	
}

extension ESI.Contracts.Contract {
	var currentStatus: ESI.Contracts.Contract.Status {
		switch status {
		case .outstanding, .inProgress:
			return dateExpired < Date() ? .finished : status
		default:
			return status
		}
	}
	var isOpen: Bool {
		return dateExpired > Date() && (status == .outstanding || status == .inProgress)
	}
}

extension ESI.Wallet.RefType {
	var title: String {
		return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
	}
}
