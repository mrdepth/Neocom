//
//  Router.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

extension UIStoryboard {
	static var main: UIStoryboard { return UIStoryboard(name: "Main", bundle: nil) }
	static var database: UIStoryboard { return UIStoryboard(name: "Database", bundle: nil) }
	static var character: UIStoryboard { return UIStoryboard(name: "Character", bundle: nil) }
	static var business: UIStoryboard { return UIStoryboard(name: "Business", bundle: nil) }
	static var killReports: UIStoryboard { return UIStoryboard(name: "KillReports", bundle: nil) }
	static var fitting: UIStoryboard { return UIStoryboard(name: "Fitting", bundle: nil) }
}

enum Router {
	enum MainMenu {
		static func accounts() -> Route<Accounts> {
			return Route(assembly: Accounts.default, kind: .adaptiveModal)
		}
	}
	
	enum SDE {
		static func invCategories() -> Route<InvCategories> {
			return Route(assembly: InvCategories.default, kind: .detail)
		}
		static func invGroups(_ input: InvGroups.View.Input) -> Route<InvGroups> {
			return Route(assembly: InvGroups.default, input: input, kind: .push)
		}
		static func invTypes(_ input: InvTypes.View.Input) -> Route<InvTypes> {
			return Route(assembly: InvTypes.default, input: input, kind: .push)
		}
		static func invTypeInfo(_ input: InvTypeInfo.View.Input) -> Route<InvTypeInfo> {
			return Route(assembly: InvTypeInfo.default, input: input, kind: .adaptiveModal)
		}
		static func invTypeVariations(_ input: InvTypeVariations.View.Input) -> Route<InvTypeVariations> {
			return Route(assembly: InvTypeVariations.default, input: input, kind: .push)
		}
		static func invTypeMastery(_ input: InvTypeMastery.View.Input) -> Route<InvTypeMastery> {
			return Route(assembly: InvTypeMastery.default, input: input, kind: .push)
		}
		static func invTypeMarketOrders(_ input: InvTypeMarketOrders.View.Input) -> Route<InvTypeMarketOrders> {
			return Route(assembly: InvTypeMarketOrders.default, input: input, kind: .push)
		}
		static func mapLocationPicker(_ input: MapLocationPicker.View.Input) -> Route<MapLocationPicker> {
			return Route(assembly: MapLocationPicker.default, input: input, kind: .adaptiveModal)
		}
		static func mapLocationPickerSolarSystems(_ input: MapLocationPickerSolarSystems.View.Input) -> Route<MapLocationPickerSolarSystems> {
			return Route(assembly: MapLocationPickerSolarSystems.default, input: input, kind: .push)
		}
		static func certGroups() -> Route<CertGroups> {
			return Route(assembly: CertGroups.default, kind: .detail)
		}
		static func certCertificates(_ input: CertCertificates.View.Input) -> Route<CertCertificates> {
			return Route(assembly: CertCertificates.default, input: input, kind: .push)
		}
		static func certCertificateInfo(_ input: CertCertificateInfo.View.Input) -> Route<CertCertificateInfo> {
			return Route(assembly: CertCertificateInfo.default, input: input, kind: .push)
		}


	}
}

