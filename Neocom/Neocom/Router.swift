//
//  Router.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

extension UIStoryboard {
	static var main: UIStoryboard { return UIStoryboard(name: "Main", bundle: nil) }
	static var database: UIStoryboard { return UIStoryboard(name: "Database", bundle: nil) }
	static var character: UIStoryboard { return UIStoryboard(name: "Character", bundle: nil) }
	static var business: UIStoryboard { return UIStoryboard(name: "Business", bundle: nil) }
	static var killReports: UIStoryboard { return UIStoryboard(name: "KillReports", bundle: nil) }
	static var fitting: UIStoryboard { return UIStoryboard(name: "Fitting", bundle: nil) }
}

enum Router {
	
//	static func custom(_ block: @escaping (UIViewController, Any?) -> Future<Bool>) -> CustomRoute {
//		return CustomRoute(block)
//	}
//
//	static func custom(_ block: @escaping (UIViewController, Any?) -> Void) -> CustomRoute {
//		return CustomRoute( {
//			block($0, $1)
//			return .init(true)
//		})
//	}

	enum MainMenu {
		static func accounts() -> Route<Accounts> {
			return Route(assembly: Accounts.default, kind: .adaptiveModal)
		}
		static func mail() -> Route<Neocom.Mail> {
			return Route(assembly: Neocom.Mail.default, kind: .detail)
		}
		static func npc(_ input: NpcGroups.View.Input = .root) -> Route<NpcGroups> {
			return Route(assembly: NpcGroups.default, input: input, kind: .detail)
		}
		static func incursion() -> Route<Incursions> {
			return Route(assembly: Incursions.default, kind: .detail)
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
		static func invTypeRequiredFor(_ input: InvTypeRequiredFor.View.Input) -> Route<InvTypeRequiredFor> {
			return Route(assembly: InvTypeRequiredFor.default, input: input, kind: .push)
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
		static func invMarket() -> Route<InvMarket> {
			return Route(assembly: InvMarket.default, kind: .detail)
		}
		static func invMarketGroups(_ input: InvMarketGroups.View.Input) -> Route<InvMarketGroups> {
			return Route(assembly: InvMarketGroups.default, input: input, kind: .push)
		}
		static func whTypes() -> Route<WhTypes> {
			return Route(assembly: WhTypes.default, kind: .push)
		}
		static func npcGroups(_ input: NpcGroups.View.Input = .root) -> Route<NpcGroups> {
			return Route(assembly: NpcGroups.default, input: input, kind: .detail)
		}
	}
	
	enum Character {
		static func skills() -> Route<SkillsContainer> {
			return Route(assembly: SkillsContainer.default, kind: .detail)
		}
		static func mySkills() -> Route<MySkills> {
			return Route(assembly: MySkills.default, kind: .push)
		}
		static func characterInfo() -> Route<CharacterInfo> {
			return Route(assembly: CharacterInfo.default, kind: .detail)
		}
		static func jumpClones() -> Route<JumpClones> {
			return Route(assembly: JumpClones.default, kind: .detail)
		}
	}
	
	enum Mail {
		static func mailBody(_ input: MailBody.View.Input) -> Route<MailBody> {
			return Route(assembly: MailBody.default, input: input, kind: .push)
		}
		static func newMail(_ input: NewMail.View.Input) -> Route<NewMail> {
			return Route(assembly: NewMail.default, input: input, kind: .adaptiveModal)
		}
	}
	
	enum Business {
		static func assets() -> Route<Assets> {
			return Route(assembly: Assets.default, kind: .detail)
		}
		static func marketOrders() -> Route<MarketOrders> {
			return Route(assembly: MarketOrders.default, kind: .detail)
		}
		static func industryJobs() -> Route<IndustryJobs> {
			return Route(assembly: IndustryJobs.default, kind: .detail)
		}
		static func contracts() -> Route<Contracts> {
			return Route(assembly: Contracts.default, kind: .detail)
		}
		static func contractInfo(_ input: ContractInfo.View.Input) -> Route<ContractInfo> {
			return Route(assembly: ContractInfo.default, input: input, kind: .push)
		}
		static func walletJournal() -> Route<WalletJournalPage> {
			return Route(assembly: WalletJournalPage.default, kind: .detail)
		}
		static func walletTransactions() -> Route<WalletTransactionsPage> {
			return Route(assembly: WalletTransactionsPage.default, kind: .detail)
		}
	}
	
	enum KillReports {
		static func killmails() -> Route<Killmails> {
			return Route(assembly: Killmails.default, kind: .detail)
		}
		static func killmailInfo(_ input: KillmailInfo.View.Input) -> Route<KillmailInfo> {
			return Route(assembly: KillmailInfo.default, input: input, kind: .detail)
		}
		static func zKillboard() -> Route<ZKillboard> {
			return Route(assembly: ZKillboard.default, kind: .detail)
		}
		static func zKillmails(_ input: ZKillmails.View.Input) -> Route<ZKillmails> {
			return Route(assembly: ZKillmails.default, input: input, kind: .push)
		}
		static func datePicker(_ input: DatePicker.View.Input) -> Route<DatePicker> {
			return Route(assembly: DatePicker.default, input: input, kind: .sheet)
		}
		static func contacts(_ input: Contacts.View.Input) -> Route<Contacts> {
			return Route(assembly: Contacts.default, input: input, kind: .adaptiveModal)
		}
		static func typePicker(_ input: @escaping ZKillboardTypePicker.View.Input) -> Route<ZKillboardTypePicker> {
			return Route(assembly: ZKillboardTypePicker.default, input: input, kind: .modal)
		}
		static func typePickerInvGroups(_ input: ZKillboardInvGroups.View.Input) -> Route<ZKillboardInvGroups> {
			return Route(assembly: ZKillboardInvGroups.default, input: input, kind: .push)
		}
		static func typePickerInvTypes(_ input: ZKillboardInvTypes.View.Input) -> Route<ZKillboardInvTypes> {
			return Route(assembly: ZKillboardInvTypes.default, input: input, kind: .push)
		}

	}
	
	enum Utility {
	}
}

