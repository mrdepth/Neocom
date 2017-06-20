//
//  EVEAPI+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

extension ESI.Calendar.Summary.Response {
	var title: String {
		switch self {
		case .accepted:
			return NSLocalizedString("Accepted", comment: "")
		case .declined:
			return NSLocalizedString("Declined", comment: "")
		case .notResponded:
			return NSLocalizedString("Not Responded", comment: "")
		case .tentative:
			return NSLocalizedString("Tentative", comment: "")
		}
	}
}

extension ESI.Calendar.Response.Response {
	var title: String {
		switch self {
		case .accepted:
			return NSLocalizedString("Accepted", comment: "")
		case .declined:
			return NSLocalizedString("Declined", comment: "")
		case .tentative:
			return NSLocalizedString("Tentative", comment: "")
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
