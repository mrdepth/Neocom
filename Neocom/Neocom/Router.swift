//
//  Router.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI

enum RouteKind {
	case push
	case modal
	case adaptivePush
	case adaptiveModal
	case sheet
}

class Route/*: Hashable*/ {
	let kind: RouteKind?
	let identifier: String?
	let storyboard: UIStoryboard?
	let viewController: () -> UIViewController?
	
	private weak var presentedViewController: UIViewController?
	
	init(kind: RouteKind? = nil, storyboard: UIStoryboard? = nil,  identifier: String? = nil, viewController: @escaping @autoclosure () -> UIViewController? = nil) {
		self.kind = kind
		self.storyboard = storyboard
		self.identifier = identifier
		self.viewController = viewController
	}
	
	func instantiateViewController() -> UIViewController {
		let controller =  viewController() ?? (storyboard ?? UIStoryboard(name: "Main", bundle: nil))!.instantiateViewController(withIdentifier: identifier!)
		prepareForSegue(destination: controller)
		return controller
	}
	
	func perform(source: UIViewController, view: UIView? = nil) {
		guard let kind = kind else {return}

		let destination = instantiateViewController()
		presentedViewController = destination
		
		
		switch kind {
		case .push:
			if source.parent is UISearchController {
				source.presentingViewController?.navigationController?.pushViewController(destination, animated: true)
			}
			else {
				((source as? UINavigationController) ?? source.navigationController)?.pushViewController(destination, animated: true)
			}
		case .modal:
			source.present(destination, animated: true, completion: nil)
			
		case .adaptivePush:
			let presentedController = source.navigationController ?? source.parent?.navigationController ?? source.parent ?? source
			if presentedController.modalPresentationStyle == .custom && presentedController.presentationController is NCSheetPresentationController {
				let destination = destination as? UINavigationController ?? NCNavigationController(rootViewController: destination)
				source.present(destination, animated: true, completion: nil)
				destination.topViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: .plain, target: destination, action: #selector(UIViewController.dismissAnimated(_:)))
				presentedViewController = destination
			}
			else {
                if source.parent is UISearchController {
                    source.presentingViewController?.navigationController?.pushViewController(destination, animated: true)
                }
                else {
                    source.navigationController?.pushViewController(destination, animated: true)
//                    ((source as? UINavigationController) ?? source.navigationController)?.pushViewController(destination, animated: true)
                }

			}
		case .adaptiveModal:
			let destination = destination as? UINavigationController ?? NCNavigationController(rootViewController: destination)
			destination.modalPresentationStyle = .custom
			destination.topViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: .plain, target: destination, action: #selector(UIViewController.dismissAnimated(_:)))
			presentedViewController = destination
			source.present(destination, animated: true, completion: nil)
			
		case .sheet:
			let destination = destination as? UINavigationController ?? NCNavigationController(rootViewController: destination)
			destination.modalPresentationStyle = .custom
			presentedViewController = destination
			
			let presentationController = NCSheetPresentationController(presentedViewController: destination, presenting: source)
			withExtendedLifetime(presentationController) {
				destination.transitioningDelegate = presentationController
				source.present(destination, animated: true, completion: nil)
			}
		}
	}
	
	func unwind() {
		guard let presentedViewController = presentedViewController else {return}

		if let i = presentedViewController.navigationController?.viewControllers.index(of: presentedViewController), i > 0, let prev = presentedViewController.navigationController?.viewControllers[i-1] {
			_ = presentedViewController.navigationController?.popToViewController(prev, animated: true)
		}
		else {
			presentedViewController.dismiss(animated: true, completion: nil)
		}
		//if (presentedViewController as? UINavigationController)?.dismiss(animated: true, completion: nil) == nil {
		//	_ = presentedViewController?.navigationController?.popViewController(animated: true)
		//}
	}
	
	func prepareForSegue(destination: UIViewController) {
	}
	
/*	var hashValue: Int {
		
		return (kind?.hashValue ?? 0) ^ (viewController?.hashValue ?? ((identifier?.hashValue ?? 0) ^ (storyboard?.hashValue ?? 0)))
	}
	
	static func == (lhs: Route, rhs: Route) -> Bool {
		return lhs.kind == rhs.kind && lhs.identifier == rhs.identifier && lhs.storyboard == rhs.storyboard && lhs.viewController == rhs.viewController
	}*/
}

enum Router {
	
	class Custom: Route {
		let handler: (UIViewController, UIView?) -> Void
		init(_ handler: @escaping (UIViewController, UIView?) -> Void) {
			self.handler = handler
			super.init()
		}
		
		override func perform(source: UIViewController, view: UIView?) {
			handler(source, view)
		}
	}
	
	enum Database {
		
		class TypeInfo: Route {
			let type: NCDBInvType?
			let typeID: Int?
			let objectID: NSManagedObjectID?
			
			private init(type: NCDBInvType?, typeID: Int?, objectID: NSManagedObjectID?, kind: RouteKind) {
				self.type = type
				self.typeID = typeID
				self.objectID = objectID
				super.init(kind: kind, identifier: "NCDatabaseTypeInfoViewController")
			}
			
			convenience init(_ type: NCDBInvType, kind: RouteKind = .adaptivePush) {
				self.init(type: type, typeID: nil, objectID: nil, kind: kind)
			}
			
			convenience init(_ typeID: Int, kind: RouteKind = .adaptivePush) {
				self.init(type: nil, typeID: typeID, objectID: nil, kind: kind)
			}
			
			convenience init(_ objectID: NSManagedObjectID, kind: RouteKind = .adaptivePush) {
				self.init(type: nil, typeID: nil, objectID: objectID, kind: kind)
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCDatabaseTypeInfoViewController
				if let type = type {
					destination.type = type
				}
				else if let typeID = typeID {
					destination.type = NCDatabase.sharedDatabase?.invTypes[typeID]
				}
				else if let objectID = objectID {
					destination.type = (try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: objectID)) as? NCDBInvType
				}
			}
		}
		
		class Groups: Route {
			let category: NCDBInvCategory?
			let categoryID: Int?
			let objectID: NSManagedObjectID?
			
			private init(category: NCDBInvCategory?, categoryID: Int?, objectID: NSManagedObjectID?, kind: RouteKind) {
				self.category = category
				self.categoryID = categoryID
				self.objectID = objectID
				super.init(kind: kind, identifier: "NCDatabaseGroupsViewController")
			}
			
			convenience init(_ category: NCDBInvCategory, kind: RouteKind = .adaptivePush) {
				self.init(category: category, categoryID: nil, objectID: nil, kind: kind)
			}
			
			convenience init(_ categoryID: Int, kind: RouteKind = .adaptivePush) {
				self.init(category: nil, categoryID: categoryID, objectID: nil, kind: kind)
			}
			
			convenience init(_ objectID: NSManagedObjectID, kind: RouteKind = .adaptivePush) {
				self.init(category: nil, categoryID: nil, objectID: objectID, kind: kind)
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCDatabaseGroupsViewController
				if let category = category {
					destination.category = category
				}
				else if let categoryID = categoryID {
					destination.category = NCDatabase.sharedDatabase?.invCategories[categoryID]
				}
				else if let objectID = objectID {
					destination.category = (try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: objectID)) as? NCDBInvCategory
				}
			}
		}

		class MarketGroups: Route {
			let parentGroup: NCDBInvMarketGroup?
			
			init(parentGroup: NCDBInvMarketGroup?) {
				self.parentGroup = parentGroup
				super.init(kind: .push, identifier: "NCMarketGroupsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCMarketGroupsViewController
				destination.parentGroup = parentGroup
			}
		}
		
		class NpcGroups: Route {
			let parentGroup: NCDBNpcGroup?
			
			init(parentGroup: NCDBNpcGroup?) {
				self.parentGroup = parentGroup
				super.init(kind: .push, identifier: "NCNPCViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCNPCViewController
				destination.parentGroup = parentGroup
			}
		}
		
		class Types: Route {
			let predicate: NSPredicate
			let title: String?
			
			private init(predicate: NSPredicate, title: String?) {
				self.predicate = predicate
				self.title = title
				super.init(kind: .push, identifier: "NCDatabaseTypesViewController")
			}
			
			convenience init(group: NCDBInvGroup) {
				self.init(predicate: NSPredicate(format: "group = %@", group), title: group.groupName)
			}

			convenience init(marketGroup: NCDBInvMarketGroup) {
				self.init(predicate: NSPredicate(format: "marketGroup = %@", marketGroup), title: marketGroup.marketGroupName)
			}

			convenience init(npcGroup: NCDBNpcGroup) {
				self.init(predicate: NSPredicate(format: "group = %@", npcGroup.group!), title: npcGroup.npcGroupName)
			}

			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCDatabaseTypesViewController
				destination.predicate = predicate
				destination.title = title
			}
		}

		class TypePicker: Route {
			let category: NCDBDgmppItemCategory
			let completionHandler: (NCTypePickerViewController, NCDBInvType) -> Void
			
			init(category: NCDBDgmppItemCategory, completionHandler: @escaping (NCTypePickerViewController, NCDBInvType) -> Void) {
				self.category = category
				self.completionHandler = completionHandler
				super.init(kind: .modal, identifier: "NCTypePickerViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCTypePickerViewController
				destination.category = category
				destination.completionHandler = completionHandler
			}

		}
		
		class MarketInfo: Route {
			let type: NCDBInvType?
			let typeID: Int?
			let objectID: NSManagedObjectID?
			
			private init(type: NCDBInvType?, typeID: Int?, objectID: NSManagedObjectID?, kind: RouteKind) {
				self.type = type
				self.typeID = typeID
				self.objectID = objectID
				super.init(kind: kind, identifier: "NCDatabaseMarketInfoViewController")
			}
			
			convenience init(_ type: NCDBInvType, kind: RouteKind = .adaptivePush) {
				self.init(type: type, typeID: nil, objectID: nil, kind: kind)
			}
			
			convenience init(_ typeID: Int, kind: RouteKind = .adaptivePush) {
				self.init(type: nil, typeID: typeID, objectID: nil, kind: kind)
			}
			
			convenience init(_ objectID: NSManagedObjectID, kind: RouteKind = .adaptivePush) {
				self.init(type: nil, typeID: nil, objectID: objectID, kind: kind)
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCDatabaseMarketInfoViewController
				if let type = type {
					destination.type = type
				}
				else if let typeID = typeID {
					destination.type = NCDatabase.sharedDatabase?.invTypes[typeID]
				}
				else if let objectID = objectID {
					destination.type = (try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: objectID)) as? NCDBInvType
				}
			}
		}

		class Certificates: Route {
			let group: NCDBInvGroup
			
			init(group: NCDBInvGroup) {
				self.group = group
				super.init(kind: .push, identifier: "NCDatabaseCertificatesViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCDatabaseCertificatesViewController
				destination.group = group
			}
		}
		
		class CertificateInfo: Route {
			let certificate: NCDBCertCertificate
			
			init(certificate: NCDBCertCertificate) {
				self.certificate = certificate
				super.init(kind: .push, identifier: "NCDatabaseCertificateInfoViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCDatabaseCertificateInfoViewController
				destination.certificate = certificate
			}
		}
		
		class TypeMastery: Route {
			let typeObjectID: NSManagedObjectID
			let masteryLevelObjectID: NSManagedObjectID
			
			init(typeObjectID: NSManagedObjectID, masteryLevelObjectID: NSManagedObjectID) {
				self.typeObjectID = typeObjectID
				self.masteryLevelObjectID = masteryLevelObjectID
				super.init(kind: .push, identifier: "NCDatabaseTypeMasteryViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCDatabaseTypeMasteryViewController
				let context = NCDatabase.sharedDatabase?.viewContext
				destination.type = (try? context?.existingObject(with: typeObjectID)) as? NCDBInvType
				destination.level = (try? context?.existingObject(with: masteryLevelObjectID)) as? NCDBCertMasteryLevel
			}
		}

	}
	
	enum Character {
		
		class Skills: Route {

			init() {
				super.init(kind: .push, identifier: "NCSkillsViewController")
			}
			
		}
	}
	
	enum Fitting {
		
		class Editor: Route {
			let fleet: NCFittingFleet
			let engine: NCFittingEngine
			
			init(fleet: NCFittingFleet, engine: NCFittingEngine) {
				self.fleet = fleet
				self.engine = engine
				super.init(kind: .push, identifier: "NCFittingEditorViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingEditorViewController
				destination.fleet = fleet
				destination.engine = engine
			}
		}
		
		class Ammo: Route {
			let category: NCDBDgmppItemCategory
			let completionHandler: (NCFittingAmmoViewController, NCDBInvType?) -> Void
			let modules: [NCFittingModule]
			
			init(category: NCDBDgmppItemCategory, modules: [NCFittingModule], completionHandler: @escaping (NCFittingAmmoViewController, NCDBInvType?) -> Void) {
				self.category = category
				self.completionHandler = completionHandler
				self.modules = modules
				super.init(kind: .adaptivePush, identifier: "NCFittingAmmoViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingAmmoViewController
				destination.category = category
				destination.modules = modules
				destination.completionHandler = completionHandler
			}
		}

		class AmmoDamageChart: Route {
			let category: NCDBDgmppItemCategory
			let modules: [NCFittingModule]
			
			init(category: NCDBDgmppItemCategory, modules: [NCFittingModule]) {
				self.category = category
				self.modules = modules
				super.init(kind: .adaptivePush, identifier: "NCFittingAmmoDamageChartViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingAmmoDamageChartViewController
				destination.category = category
				destination.modules = modules
			}
		}
		
		class AreaEffects: Route {
			let completionHandler: (NCFittingAreaEffectsViewController, NCDBInvType?) -> Void
			
			init(completionHandler: @escaping (NCFittingAreaEffectsViewController, NCDBInvType?) -> Void) {
				self.completionHandler = completionHandler
				super.init(kind: .adaptivePush, identifier: "NCFittingAreaEffectsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				(destination as! NCFittingAreaEffectsViewController).completionHandler = completionHandler
			}
		}
		
		class DamagePatterns: Route {
			let completionHandler: (NCFittingDamagePatternsViewController, NCFittingDamage) -> Void
			
			init(completionHandler: @escaping (NCFittingDamagePatternsViewController, NCFittingDamage) -> Void) {
				self.completionHandler = completionHandler
				super.init(kind: .adaptivePush, identifier: "NCFittingDamagePatternsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				(destination as! NCFittingDamagePatternsViewController).completionHandler = completionHandler
			}
		}
		
		class Variations: Route {
			let type: NCDBInvType
			let completionHandler: (NCFittingVariationsViewController, NCDBInvType) -> Void
			
			init(type: NCDBInvType, completionHandler: @escaping (NCFittingVariationsViewController, NCDBInvType) -> Void) {
				self.type = type
				self.completionHandler = completionHandler
				super.init(kind: .adaptivePush, identifier: "NCFittingVariationsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingVariationsViewController
				destination.type = type
				destination.completionHandler = completionHandler
			}
		}

		class ModuleActions: Route {
			let modules: [NCFittingModule]
			
			init(_ modules: [NCFittingModule]) {
				self.modules = modules
				super.init(kind: .sheet, identifier: "NCFittingModuleActionsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				(destination as! NCFittingModuleActionsViewController).modules = modules
			}
		}
		
		class DroneActions: Route {
			let drones: [NCFittingDrone]
			
			init(_ drones: [NCFittingDrone]) {
				self.drones = drones
				super.init(kind: .sheet, identifier: "NCFittingDroneActionsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				(destination as! NCFittingDroneActionsViewController).drones = drones
			}
		}
		
		class FleetMemberPicker: Route {
			let fleet: NCFittingFleet
			let completionHandler: (NCFittingFleetMemberPickerViewController) -> Void
			
			init(fleet: NCFittingFleet, completionHandler: @escaping (NCFittingFleetMemberPickerViewController) -> Void) {
				self.fleet = fleet
				self.completionHandler = completionHandler
				super.init(kind: .adaptivePush, identifier: "NCFittingFleetMemberPickerViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingFleetMemberPickerViewController
				destination.fleet = fleet
				destination.completionHandler = completionHandler
			}
		}

		class Targets: Route {
			let modules: [NCFittingModule]
			let completionHandler: (NCFittingTargetsViewController, NCFittingShip?) -> Void
			
			init(modules: [NCFittingModule], completionHandler: @escaping (NCFittingTargetsViewController, NCFittingShip?) -> Void) {
				self.modules = modules
				self.completionHandler = completionHandler
				super.init(kind: .adaptivePush, identifier: "NCFittingTargetsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingTargetsViewController
				destination.modules = modules
				destination.completionHandler = completionHandler
			}
		}

		class Characters: Route {
			let pilot: NCFittingCharacter
			let completionHandler: (NCFittingCharactersViewController, URL) -> Void
			
			init(pilot: NCFittingCharacter, completionHandler: @escaping (NCFittingCharactersViewController, URL) -> Void) {
				self.pilot = pilot
				self.completionHandler = completionHandler
				super.init(kind: .adaptivePush, identifier: "NCFittingCharactersViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingCharactersViewController
				destination.pilot = pilot
				destination.completionHandler = completionHandler
			}
		}
		
		class CharacterEditor: Route {
			let character: NCFitCharacter
			
			init(character: NCFitCharacter, kind: RouteKind = .adaptivePush) {
				self.character = character
				super.init(kind: kind, identifier: "NCFittingCharacterEditorViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingCharacterEditorViewController
				destination.character = character
			}
		}
	}
	
	enum Mail {
		
		class Body: Route {
			let mail: ESI.Mail.Header
			
			init(mail: ESI.Mail.Header) {
				self.mail = mail
				super.init(kind: .push, identifier: "NCMailBodyViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCMailBodyViewController
				destination.mail = mail
			}
		}
		
		class NewMessage: Route {
			let recipients: [Int64]?
			let subject: String?
			let body: NSAttributedString?
			let draft: NCMailDraft?
			
			init(recipients: [Int64]? = nil, subject: String? = nil, body: NSAttributedString? = nil) {
				self.recipients = recipients
				self.subject = subject
				self.body = body
				self.draft = nil
				super.init(kind: .modal, identifier: "NCNewMailNavigationController")
			}

			init(draft: NCMailDraft) {
				self.recipients = nil
				self.subject = nil
				self.body = nil
				self.draft = draft
				super.init(kind: .modal, identifier: "NCNewMailNavigationController")
			}

			override func prepareForSegue(destination: UIViewController) {
				let destination = (destination as! UINavigationController).topViewController as! NCNewMailViewController
				destination.recipients = draft?.to ?? recipients ?? []
				destination.subject = draft?.subject ?? subject
				destination.body = draft?.body ?? body
				destination.draft = draft
			}

		}
	}
	
	enum Wealth {
		
		class Assets: Route {
			let assets: [ESI.Assets.Asset]
			let prices: [Int: Double]
			
			init(assets: [ESI.Assets.Asset], prices: [Int: Double]) {
				self.assets = assets
				self.prices = prices
				super.init(kind: .push, identifier: "NCWealthAssetsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCWealthAssetsViewController
				destination.assets = assets
				destination.prices = prices
			}
		}
	}
	
	enum Contract {
		
		class Info: Route {
			let contract: ESI.Contracts.Contract
			
			init(contract: ESI.Contracts.Contract) {
				self.contract = contract
				super.init(kind: .push, identifier: "NCContractInfoViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCContractInfoViewController
				destination.contract = contract
			}
		}
	}
	
	enum Calendar {
		
		class Event: Route {
			let event: ESI.Calendar.Summary
			
			init(event: ESI.Calendar.Summary) {
				self.event = event
				super.init(kind: .push, identifier: "NCEventViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCEventViewController
				destination.event = event
			}
		}
	}
	
	enum KillReports {
		
		class Info: Route {
			let killmail: NCKillmail
			
			init(killmail: NCKillmail) {
				self.killmail = killmail
				super.init(kind: .push, identifier: "NCKillmailInfoViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCKillmailInfoViewController
				destination.killmail = killmail
			}
		}
		
		class SearchContact: Route {
			let delegate: NCContactsSearchResultViewControllerDelegate
			
			init(delegate: NCContactsSearchResultViewControllerDelegate) {
				self.delegate = delegate
				super.init(kind: .adaptiveModal, identifier: "NCZKillboardContactsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCZKillboardContactsViewController
				destination.delegate = delegate
			}
		}
		
		class TypePicker: Route {
			let completionHandler: (NCZKillboardTypePickerViewController, Any) -> Void
			
			init(completionHandler: @escaping (NCZKillboardTypePickerViewController, Any) -> Void) {
				self.completionHandler = completionHandler
				super.init(kind: .modal, identifier: "NCZKillboardTypePickerViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCZKillboardTypePickerViewController
				destination.completionHandler = completionHandler
			}
			
		}

		class Groups: Route {
			let category: NCDBInvCategory
			
			init(category: NCDBInvCategory) {
				self.category = category
				super.init(kind: .push, identifier: "NCZKillboardGroupsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCZKillboardGroupsViewController
				destination.category = category
			}
		}
		
		class Types: Route {
			let predicate: NSPredicate
			let title: String?
			
			private init(predicate: NSPredicate, title: String?) {
				self.predicate = predicate
				self.title = title
				super.init(kind: .push, identifier: "NCZKillboardTypesViewController")
			}
			
			convenience init(group: NCDBInvGroup) {
				self.init(predicate: NSPredicate(format: "group == %@ AND published == TRUE", group), title: group.groupName)
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCZKillboardTypesViewController
				destination.predicate = predicate
				destination.title = title
			}
		}

		class RegionPicker: Route {
			let completionHandler: (NCZKillboardRegionPickerViewController, Any) -> Void
			
			init(completionHandler: @escaping (NCZKillboardRegionPickerViewController, Any) -> Void) {
				self.completionHandler = completionHandler
				super.init(kind: .modal, identifier: "NCZKillboardRegionPickerViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCZKillboardRegionPickerViewController
				destination.completionHandler = completionHandler
			}
			
		}

		class SolarSystems: Route {
			let region: NCDBMapRegion
			
			init(region: NCDBMapRegion) {
				self.region = region
				super.init(kind: .push, identifier: "NCZKillboardSolarSystemsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCZKillboardSolarSystemsViewController
				destination.region = region
			}
		}
		
		class ZKillboardReports: Route {
			let filter: [ZKillboard.Filter]
			
			init(filter: [ZKillboard.Filter]) {
				self.filter = filter
				super.init(kind: .push, identifier: "NCZKillboardKillmailsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCZKillboardKillmailsViewController
				destination.filter = filter
			}
		}

		class ContactReports: Route {
			let contact: NCContact
			
			init(contact: NCContact) {
				self.contact = contact
				super.init(kind: .push, identifier: "NCZKillboardSummaryViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCZKillboardSummaryViewController
				destination.contact = contact
			}
		}

		class RelatedKills: Route {
			let filter: [ZKillboard.Filter]
			
			init(killmail: NCKillmail) {
				filter = [.solarSystemID([killmail.solarSystemID]), .startTime(killmail.killmailTime.addingTimeInterval(-3600)), .endTime(killmail.killmailTime.addingTimeInterval(3600))]
				super.init(kind: .push, identifier: "NCZKillboardKillmailsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCZKillboardKillmailsViewController
				destination.filter = filter
			}
		}
	}
	
	enum RSS {
		
		class Channel: Route {
			let url: URL
			let title: String
			
			init(url: URL, title: String) {
				self.url = url
				self.title = title
				super.init(kind: .push, identifier: "NCFeedChannelViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFeedChannelViewController
				destination.url = url
				destination.title = title
			}
		}
		
		class Item: Route {
			let item: EVEAPI.RSS.Item
			init(item: EVEAPI.RSS.Item) {
				self.item = item
				super.init(kind: .push, viewController: NCFeedItemViewController())
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFeedItemViewController
				destination.item = item
			}
		}
	}
}
