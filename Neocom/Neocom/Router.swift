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
import Dgmpp


extension UIStoryboard {
	static let main = UIStoryboard(name: "Main", bundle: nil)
	static let database = UIStoryboard(name: "Database", bundle: nil)
	static let character = UIStoryboard(name: "Character", bundle: nil)
	static let business = UIStoryboard(name: "Business", bundle: nil)
	static let killReports = UIStoryboard(name: "KillReports", bundle: nil)
	static let fitting = UIStoryboard(name: "Fitting", bundle: nil)
}

enum RouteKind {
	case push
	case modal
	case adaptivePush
	case adaptiveModal
	case sheet
	case popover
	case detail
}

//class NCAdaptivePageSheetDelegate: NSObject, UIAdaptivePresentationControllerDelegate {
//	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
//		return traitCollection.horizontalSizeClass == .compact ? .overFullScreen : .none
//	}
//}

class NCAdaptivePopoverDelegate: NSObject, UIPopoverPresentationControllerDelegate {
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		return .none
	}
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
		let controller =  viewController() ?? (storyboard ?? UIStoryboard.main)!.instantiateViewController(withIdentifier: identifier!)
		prepareForSegue(destination: controller)
		return controller
	}
	
	private var adaptiveDelegate: Any?
	
	func perform(source: UIViewController, sender: Any?) {
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
			destination.modalPresentationStyle = .pageSheet
			if (destination as? UINavigationController)?.viewControllers.first?.navigationItem.leftBarButtonItem == nil {
				NCSlideDownDismissalInteractiveTransitioning.add(to: destination)
			}
			
			source.present(destination, animated: true, completion: nil)
			
		case .adaptivePush:
			let presentedController = source.navigationController ?? source.parent?.navigationController ?? source.parent ?? source
			if presentedController.presentationController is NCSheetPresentationController || presentedController.presentationController is UIPopoverPresentationController {
				let destination = destination as? UINavigationController ?? NCNavigationController(rootViewController: destination)
				destination.modalPresentationStyle = .pageSheet

//				let delegate = NCAdaptivePageSheetDelegate()
//				destination.presentationController?.delegate = delegate
//				adaptiveDelegate = delegate
				
				let firstVC = destination.viewControllers.first
				if firstVC?.navigationItem.leftBarButtonItem == nil {
					NCSlideDownDismissalInteractiveTransitioning.add(to: destination)
					firstVC?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: .plain, target: destination, action: #selector(UIViewController.dismissAnimated(_:)))
				}
				
				presentedViewController = destination
				source.present(destination, animated: true, completion: nil)
			}
			else {
                if source.parent is UISearchController {
                    source.presentingViewController?.navigationController?.pushViewController(destination, animated: true)
                }
                else {
                    source.navigationController?.pushViewController(destination, animated: true)
                }

			}
		case .adaptiveModal:
			let destination = destination as? UINavigationController ?? NCNavigationController(rootViewController: destination)
			destination.modalPresentationStyle = .custom
			
			let firstVC = destination.viewControllers.first
			if firstVC?.navigationItem.leftBarButtonItem == nil {
				NCSlideDownDismissalInteractiveTransitioning.add(to: destination)
				firstVC?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: .plain, target: destination, action: #selector(UIViewController.dismissAnimated(_:)))
			}

			NCSlideDownDismissalInteractiveTransitioning.add(to: destination)
			
			presentedViewController = destination
			source.present(destination, animated: true, completion: nil)
			
		case .sheet:
			let destination = destination as? UINavigationController ?? NCNavigationController(rootViewController: destination)
			if source.traitCollection.userInterfaceIdiom == .pad {
				let delegate = NCAdaptivePopoverDelegate()
				
				destination.modalPresentationStyle = .popover
				destination.popoverPresentationController?.delegate = delegate
				source.present(destination, animated: true, completion: nil)
				
				let presentationController = destination.popoverPresentationController
				presentationController?.permittedArrowDirections = .any
				presentationController?.backgroundColor = .separator
				if let view = sender as? UIView {
					presentationController?.sourceView = view
					presentationController?.sourceRect = view.bounds
				}
				else if let item = sender as? UIBarButtonItem {
					presentationController?.barButtonItem = item
				}
				
				adaptiveDelegate = delegate
			}
			else {
				destination.modalPresentationStyle = .custom
				
				
				let presentationController = NCSheetPresentationController(presentedViewController: destination, presenting: source)
				
				withExtendedLifetime(presentationController) {
					destination.transitioningDelegate = presentationController
					source.present(destination, animated: true, completion: nil)
				}
			}
			presentedViewController = destination

		case .popover:
			let destination = destination as? UINavigationController ?? NCNavigationController(rootViewController: destination)
			
			destination.modalPresentationStyle = .popover

			source.present(destination, animated: true, completion: nil)

			
			let firstVC = destination.viewControllers.first
			if firstVC?.navigationItem.leftBarButtonItem == nil {
				NCSlideDownDismissalInteractiveTransitioning.add(to: destination)
				firstVC?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: .plain, target: destination, action: #selector(UIViewController.dismissAnimated(_:)))
			}
			
			let presentationController = destination.popoverPresentationController
			presentationController?.backgroundColor = .separator
			presentationController?.permittedArrowDirections = .any
			if let view = sender as? UIView {
				presentationController?.sourceView = view
				presentationController?.sourceRect = view.bounds
			}
			else if let item = sender as? UIBarButtonItem {
				presentationController?.barButtonItem = item
			}
		case .detail:
			let destination = destination as? UINavigationController ?? NCNavigationController(rootViewController: destination)
			source.showDetailViewController(destination, sender: sender)
			presentedViewController = destination
		}
		
		presentedViewController?.route = self
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
		let handler: (UIViewController, Any?) -> Void
		init(_ handler: @escaping (UIViewController, Any?) -> Void) {
			self.handler = handler
			super.init()
		}
		
		override func perform(source: UIViewController, sender: Any?) {
			handler(source, sender)
		}
	}
	
	enum Database {
		
		class TypeInfo: Route {
			var type: NCDBInvType?
			var typeID: Int?
			var objectID: NSManagedObjectID?
			var fittingType: DGMType?
			var attributeValues: [Int: Float]?
			
			private init(type: NCDBInvType?, typeID: Int?, objectID: NSManagedObjectID?, fittingType: DGMType?, kind: RouteKind) {
				self.type = type
				self.typeID = typeID
				self.objectID = objectID
				self.fittingType = fittingType
				super.init(kind: kind, storyboard: UIStoryboard.database, identifier: "NCDatabaseTypeInfoViewController")
			}
			
			convenience init(_ type: NCDBInvType, kind: RouteKind = .adaptivePush) {
				self.init(type: type, typeID: nil, objectID: nil, fittingType: nil, kind: kind)
			}
			
			convenience init(_ typeID: Int, kind: RouteKind = .adaptivePush) {
				self.init(type: nil, typeID: typeID, objectID: nil, fittingType: nil, kind: kind)
			}
			
			convenience init(_ objectID: NSManagedObjectID, kind: RouteKind = .adaptivePush) {
				self.init(type: nil, typeID: nil, objectID: objectID, fittingType: nil, kind: kind)
			}

			convenience init(_ fittingType: DGMType, kind: RouteKind = .adaptivePush) {
				self.init(type: nil, typeID: nil, objectID: nil, fittingType: fittingType, kind: kind)
			}

			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCDatabaseTypeInfoViewController
				destination.attributeValues = attributeValues
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
			
			override func perform(source: UIViewController, sender: Any?) {
				if let fittingType = fittingType {
					NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
						let typeID = fittingType.typeID
						var attributes = [Int: Float]()
//						fittingItem.engine?.performBlockAndWait {
							guard let type = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)[typeID] else {return}
							type.attributes?.forEach {
								guard let attribute = $0 as? NCDBDgmTypeAttribute else {return}
								guard let attributeType = attribute.attributeType else {return}
								if let value = fittingType[DGMAttributeID(attributeType.attributeID)]?.value {
									attributes[Int(attributeType.attributeID)] = Float(value)
								}
							}
//						}
						DispatchQueue.main.async {
							self.attributeValues = attributes
							self.typeID = typeID
							super.perform(source: source, sender: sender)
						}
					}
				}
				else {
					super.perform(source: source, sender: sender)
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
				super.init(kind: kind, storyboard: UIStoryboard.database, identifier: "NCDatabaseGroupsViewController")
			}
			
			convenience init(_ category: NCDBInvCategory, kind: RouteKind = .push) {
				self.init(category: category, categoryID: nil, objectID: nil, kind: kind)
			}
			
			convenience init(_ categoryID: Int, kind: RouteKind = .push) {
				self.init(category: nil, categoryID: categoryID, objectID: nil, kind: kind)
			}
			
			convenience init(_ objectID: NSManagedObjectID, kind: RouteKind = .push) {
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
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCMarketGroupsViewController")
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
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCNPCViewController")
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
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCDatabaseTypesViewController")
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
			var category: NCDBDgmppItemCategory?
			var completionHandler: ((NCTypePickerViewController, NCDBInvType) -> Void)?
			
			convenience init() {
				self.init(category: nil, completionHandler: nil)
			}
			
			init(category: NCDBDgmppItemCategory?, completionHandler: ((NCTypePickerViewController, NCDBInvType) -> Void)?) {
				self.category = category
				self.completionHandler = completionHandler
				super.init(kind: .popover, storyboard: UIStoryboard.database, identifier: "NCTypePickerViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCTypePickerViewController
				destination.category = category
				destination.completionHandler = completionHandler
			}

		}
		
		class TypePickerGroups: Route {
			let parentGroup: NCDBDgmppItemGroup?
			
			init(parentGroup: NCDBDgmppItemGroup?) {
				self.parentGroup = parentGroup
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCTypePickerGroupsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCTypePickerGroupsViewController
				destination.parentGroup = parentGroup
			}
		}
		
		class TypePickerTypes: Route {
			let predicate: NSPredicate
			let title: String?
			
			private init(predicate: NSPredicate, title: String?) {
				self.predicate = predicate
				self.title = title
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCTypePickerTypesViewController")
			}
			
			convenience init(group: NCDBDgmppItemGroup) {
				self.init(predicate: NSPredicate(format: "dgmppItem.groups CONTAINS %@", group), title: group.groupName)
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCTypePickerTypesViewController
				destination.predicate = predicate
				destination.title = title
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
				super.init(kind: kind, storyboard: UIStoryboard.database, identifier: "NCDatabaseMarketInfoViewController")
			}
			
			convenience init(_ type: NCDBInvType, kind: RouteKind = .push) {
				self.init(type: type, typeID: nil, objectID: nil, kind: kind)
			}
			
			convenience init(_ typeID: Int, kind: RouteKind = .push) {
				self.init(type: nil, typeID: typeID, objectID: nil, kind: kind)
			}
			
			convenience init(_ objectID: NSManagedObjectID, kind: RouteKind = .push) {
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
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCDatabaseCertificatesViewController")
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
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCDatabaseCertificateInfoViewController")
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
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCDatabaseTypeMasteryViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCDatabaseTypeMasteryViewController
				let context = NCDatabase.sharedDatabase?.viewContext
				destination.type = (try? context?.existingObject(with: typeObjectID)) as? NCDBInvType
				destination.level = (try? context?.existingObject(with: masteryLevelObjectID)) as? NCDBCertMasteryLevel
			}
		}
		
		class Variations: Route {
			let typeObjectID: NSManagedObjectID
			
			init(typeObjectID: NSManagedObjectID) {
				self.typeObjectID = typeObjectID
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCDatabaseTypeVariationsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCDatabaseTypeVariationsViewController
				destination.type = (try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: typeObjectID)) as? NCDBInvType
			}
		}
		
		class RequiredFor: Route {
			let typeObjectID: NSManagedObjectID
			
			init(typeObjectID: NSManagedObjectID) {
				self.typeObjectID = typeObjectID
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCDatabaseTypeRequiredForViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCDatabaseTypeRequiredForViewController
				destination.type = (try? NCDatabase.sharedDatabase?.viewContext.existingObject(with: typeObjectID)) as? NCDBInvType
			}
		}

		class NPCPicker: Route {
			let completionHandler: (NCNPCPickerViewController, NCDBInvType) -> Void
			
			init(completionHandler: @escaping (NCNPCPickerViewController, NCDBInvType) -> Void) {
				self.completionHandler = completionHandler
				super.init(kind: .popover, storyboard: UIStoryboard.database, identifier: "NCNPCPickerViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCNPCPickerViewController
				destination.completionHandler = completionHandler
			}
			
		}

		class NPCPickerGroups: Route {
			let parentGroup: NCDBNpcGroup?
			
			init(parentGroup: NCDBNpcGroup?) {
				self.parentGroup = parentGroup
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCNPCPickerGroupsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCNPCPickerGroupsViewController
				destination.parentGroup = parentGroup
			}
		}
		
		class NPCPickerTypes: Route {
			let predicate: NSPredicate
			let title: String?
			
			private init(predicate: NSPredicate, title: String?) {
				self.predicate = predicate
				self.title = title
				super.init(kind: .push, storyboard: UIStoryboard.database, identifier: "NCNPCPickerTypesViewController")
			}
			
			convenience init(npcGroup: NCDBNpcGroup) {
				self.init(predicate: NSPredicate(format: "group = %@", npcGroup.group!), title: npcGroup.npcGroupName)
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCNPCPickerTypesViewController
				destination.predicate = predicate
				destination.title = title
			}
		}
		
		class LocationPicker: Route {
			let completionHandler: (NCLocationPickerViewController, Any) -> Void
			let mode: [NCLocationPickerViewController.Mode]
			
			init(mode: [NCLocationPickerViewController.Mode], completionHandler: @escaping (NCLocationPickerViewController, Any) -> Void) {
				self.completionHandler = completionHandler
				self.mode = mode
				super.init(kind: .popover, storyboard: UIStoryboard.database, identifier: "NCLocationPickerViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCLocationPickerViewController
				destination.completionHandler = completionHandler
				destination.mode = mode
			}
			
		}
		
		class SolarSystems: Route {
			let region: NCDBMapRegion
			
			init(region: NCDBMapRegion) {
				self.region = region
				super.init(kind: .push, storyboard: .database, identifier: "NCSolarSystemsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCSolarSystemsViewController
				destination.region = region
			}
		}

	}
	
	enum Character {
		
		class Skills: Route {
			init() {
				super.init(kind: .push, storyboard: .character, identifier: "NCSkillsPageViewController")
			}
		}
		
		class LoyaltyStoreOffers: Route {
			let loyaltyPoints: ESI.Loyalty.Point
			let filter: NCLoyaltyStoreOffersViewController.Filter?
			let offers: NCCachedResult<[ESI.Loyalty.Offer]>?
			
			init(loyaltyPoints: ESI.Loyalty.Point) {
				self.loyaltyPoints = loyaltyPoints
				self.filter = nil
				self.offers = nil
				super.init(kind: .push, storyboard: .character, identifier: "NCLoyaltyStoreOffersViewController")
			}

			init(loyaltyPoints: ESI.Loyalty.Point, filter: NCLoyaltyStoreOffersViewController.Filter, offers: NCCachedResult<[ESI.Loyalty.Offer]>) {
				self.loyaltyPoints = loyaltyPoints
				self.filter = filter
				self.offers = offers
				super.init(kind: .push, storyboard: .character, identifier: "NCLoyaltyStoreOffersViewController")
			}

			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCLoyaltyStoreOffersViewController
				destination.loyaltyPoints = loyaltyPoints
				destination.filter = filter
				destination.offers = offers
			}
		}

	}

	enum Fitting {
		
		class Editor: Route {
			var fleet: NCFittingFleet?
			let typeID: Int?
			let loadoutID: NSManagedObjectID?
			let fleetID: NSManagedObjectID?
			let asset: ESI.Assets.Asset?
			let contents: [Int64: [ESI.Assets.Asset]]?
			let killmail: NCKillmail?
			let fitting: ESI.Fittings.Fitting?
			let representation: NCLoadoutRepresentation?
			
			init(typeID: Int? = nil, loadoutID: NSManagedObjectID? = nil, fleetID: NSManagedObjectID? = nil, asset: ESI.Assets.Asset? = nil, contents: [Int64: [ESI.Assets.Asset]]? = nil, killmail: NCKillmail? = nil, fitting: ESI.Fittings.Fitting? = nil, representation: NCLoadoutRepresentation? = nil) {
				self.typeID = typeID
				self.loadoutID = loadoutID
				self.fleetID = fleetID
				self.asset = asset
				self.contents = contents
				self.killmail = killmail
				self.fitting = fitting
				self.representation = representation
				super.init(kind: .push, storyboard: UIStoryboard.fitting, identifier: "NCFittingEditorViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingEditorViewController
				destination.fleet = fleet
				fleet = nil
			}
			
			override func perform(source: UIViewController, sender: Any?) {
				let progress = NCProgressHandler(viewController: source, totalUnitCount: 1)
				UIApplication.shared.beginIgnoringInteractionEvents()
//				engine.perform {
					var fleet: NCFittingFleet?
					if let typeID = self.typeID {
						fleet = try? NCFittingFleet(typeID: typeID)
					}
					else if let loadoutID = self.loadoutID {
						NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext in
							guard let loadout = (try? managedObjectContext.existingObject(with: loadoutID)) as? NCLoadout else {return}
							fleet = NCFittingFleet(loadouts: [loadout])
						}
					}
					else if let fleetID = self.fleetID {
						NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext in
							guard let fleetObject = (try? managedObjectContext.existingObject(with: fleetID)) as? NCFleet else {return}
							fleet = NCFittingFleet(fleet: fleetObject)
						}
					}
					else if let asset = self.asset, let contents = self.contents {
						fleet = try? NCFittingFleet(asset: asset, contents: contents)
					}
					else if let killmail = self.killmail {
						fleet = try? NCFittingFleet(killmail: killmail)
					}
					else if let fitting = self.fitting {
						fleet = try? NCFittingFleet(fitting: fitting)
					}
					else if let loadout = self.representation?.loadouts.first {
						fleet = try? NCFittingFleet(typeID: loadout.typeID)
						let pilot = fleet?.active
						pilot?.loadout = loadout.data
						pilot?.ship?.name = loadout.name
					}
					
					DispatchQueue.main.async {
						guard let fleet = fleet else {
							progress.finish()
							UIApplication.shared.endIgnoringInteractionEvents()
							return
						}
						if let account = NCAccount.current {
							fleet.active?.setSkills(from: account) {  _ in
								self.fleet = fleet
								super.perform(source: source, sender: sender)
								progress.finish()
								UIApplication.shared.endIgnoringInteractionEvents()
							}
						}
						else {
							fleet.active?.setSkills(level: 5) { _ in
								self.fleet = fleet
								super.perform(source: source, sender: sender)
								progress.finish()
								UIApplication.shared.endIgnoringInteractionEvents()
							}
						}
					}
				//}
			}
		}
		
		class Ammo: Route {
			let category: NCDBDgmppItemCategory
			let completionHandler: (NCFittingAmmoViewController, NCDBInvType?) -> Void
			let modules: [DGMModule]
			
			init(category: NCDBDgmppItemCategory, modules: [DGMModule], completionHandler: @escaping (NCFittingAmmoViewController, NCDBInvType?) -> Void) {
				self.category = category
				self.completionHandler = completionHandler
				self.modules = modules
				super.init(kind: .popover, storyboard: UIStoryboard.fitting, identifier: "NCFittingAmmoViewController")
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
			let modules: [DGMModule]
			
			init(category: NCDBDgmppItemCategory, modules: [DGMModule]) {
				self.category = category
				self.modules = modules
				super.init(kind: .push, storyboard: UIStoryboard.fitting, identifier: "NCFittingAmmoDamageChartViewController")
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
				super.init(kind: .popover, storyboard: UIStoryboard.fitting, identifier: "NCFittingAreaEffectsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				(destination as! NCFittingAreaEffectsViewController).completionHandler = completionHandler
			}
		}
		
		class DamagePatterns: Route {
			let completionHandler: (NCFittingDamagePatternsViewController, DGMDamageVector) -> Void
			
			init(completionHandler: @escaping (NCFittingDamagePatternsViewController, DGMDamageVector) -> Void) {
				self.completionHandler = completionHandler
				super.init(kind: .popover, storyboard: UIStoryboard.fitting, identifier: "NCFittingDamagePatternsViewController")
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
				super.init(kind: .popover, storyboard: UIStoryboard.fitting, identifier: "NCFittingVariationsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingVariationsViewController
				destination.type = type
				destination.completionHandler = completionHandler
			}
		}

		class Actions: Route {
			let fleet: NCFittingFleet
			init(fleet: NCFittingFleet) {
				self.fleet = fleet
				super.init(kind: .sheet, storyboard: UIStoryboard.fitting, identifier: "NCFittingActionsViewController")
			}

			override func prepareForSegue(destination: UIViewController) {
				(destination as! NCFittingActionsViewController).fleet = fleet
			}

		}
		
		class ModuleActions: Route {
			let modules: [DGMModule]
			let fleet: NCFittingFleet
			init(_ modules: [DGMModule], fleet: NCFittingFleet) {
				self.modules = modules
				self.fleet = fleet
				super.init(kind: .sheet, storyboard: UIStoryboard.fitting, identifier: "NCFittingModuleActionsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				(destination as! NCFittingModuleActionsViewController).modules = modules
				(destination as! NCFittingModuleActionsViewController).fleet = fleet
			}
		}
		
		class DroneActions: Route {
			let drones: [DGMDrone]
			let fleet: NCFittingFleet
			init(_ drones: [DGMDrone], fleet: NCFittingFleet) {
				self.drones = drones
				self.fleet = fleet
				super.init(kind: .sheet, storyboard: UIStoryboard.fitting, identifier: "NCFittingDroneActionsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				(destination as! NCFittingDroneActionsViewController).drones = drones
				(destination as! NCFittingDroneActionsViewController).fleet = fleet
			}
		}
		
		class FleetMemberPicker: Route {
			let fleet: NCFittingFleet
			let completionHandler: (NCFittingFleetMemberPickerViewController) -> Void
			
			init(fleet: NCFittingFleet, completionHandler: @escaping (NCFittingFleetMemberPickerViewController) -> Void) {
				self.fleet = fleet
				self.completionHandler = completionHandler
				super.init(kind: .popover, storyboard: UIStoryboard.fitting, identifier: "NCFittingFleetMemberPickerViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingFleetMemberPickerViewController
				destination.fleet = fleet
				destination.completionHandler = completionHandler
			}
		}

		class Targets: Route {
			let modules: [DGMModule]
			let completionHandler: (NCFittingTargetsViewController, DGMShip?) -> Void
			
			init(modules: [DGMModule], completionHandler: @escaping (NCFittingTargetsViewController, DGMShip?) -> Void) {
				self.modules = modules
				self.completionHandler = completionHandler
				super.init(kind: .popover, storyboard: UIStoryboard.fitting, identifier: "NCFittingTargetsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingTargetsViewController
				destination.modules = modules
				destination.completionHandler = completionHandler
			}
		}

		class Characters: Route {
			let pilot: DGMCharacter
			let completionHandler: (NCFittingCharactersViewController, URL) -> Void
			
			init(pilot: DGMCharacter, completionHandler: @escaping (NCFittingCharactersViewController, URL) -> Void) {
				self.pilot = pilot
				self.completionHandler = completionHandler
				super.init(kind: .popover, storyboard: UIStoryboard.fitting, identifier: "NCFittingCharactersViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingCharactersViewController
				destination.pilot = pilot
				destination.completionHandler = completionHandler
			}
		}
		
		class CharacterEditor: Route {
			let character: NCFitCharacter
			
			init(character: NCFitCharacter, kind: RouteKind = .push) {
				self.character = character
				super.init(kind: kind, storyboard: UIStoryboard.fitting, identifier: "NCFittingCharacterEditorViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingCharacterEditorViewController
				destination.character = character
			}
		}
		
		class RequiredSkills: Route {
			let ship: DGMShip
			
			init(for ship: DGMShip) {
				self.ship = ship
				super.init(kind: .adaptiveModal, storyboard: UIStoryboard.fitting, identifier: "NCFittingRequiredSkillsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingRequiredSkillsViewController
				destination.ship = ship
			}
		}
		
		class ImplantSet: Route {
			let character: DGMCharacter?
			let mode: NCFittingImplantSetViewController.Mode
			let completionHandler: ((NCFittingImplantSetViewController, NCImplantSet) -> Void)?
			
			private init(character: DGMCharacter?, mode: NCFittingImplantSetViewController.Mode, completionHandler: ((NCFittingImplantSetViewController, NCImplantSet) -> Void)?) {
				self.character = character
				self.mode = mode
				self.completionHandler = completionHandler
				super.init(kind: .adaptiveModal, storyboard: UIStoryboard.fitting, identifier: "NCFittingImplantSetViewController")
			}
			
			convenience init(save character: DGMCharacter?) {
				self.init(character: character, mode: .save, completionHandler: nil)
			}

			convenience init(load completionHandler: @escaping (NCFittingImplantSetViewController, NCImplantSet) -> Void) {
				self.init(character: nil, mode: .load, completionHandler: completionHandler)
			}

			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCFittingImplantSetViewController
				destination.mode = mode
				destination.completionHandler = completionHandler

				if let character = character {
//					let result: (implants: [Int], boosters: [Int])? = character.engine?.sync {
//						return (character.implants.all.map{$0.typeID}, character.boosters.all.map{$0.typeID})
//					}
					
					
					let data = NCImplantSetData()
					data.implantIDs = character.implants.map{$0.typeID}
					data.boosterIDs = character.boosters.map{$0.typeID}
					destination.implantSetData = data
				}
			}
		}
		
		class Server: Route {
			
			init() {
				super.init(kind: .adaptiveModal, storyboard: UIStoryboard.fitting, identifier: "NCFittingServerViewController")
			}
		}
	}

	enum Mail {
		
		class Body: Route {
			let mail: ESI.Mail.Header
			
			init(mail: ESI.Mail.Header) {
				self.mail = mail
				super.init(kind: .push, storyboard: UIStoryboard.character, identifier: "NCMailBodyViewController")
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
				super.init(kind: .modal, storyboard: UIStoryboard.character, identifier: "NCNewMailNavigationController")
			}

			init(draft: NCMailDraft) {
				self.recipients = nil
				self.subject = nil
				self.body = nil
				self.draft = draft
				super.init(kind: .modal, storyboard: UIStoryboard.character, identifier: "NCNewMailNavigationController")
			}

			override func prepareForSegue(destination: UIViewController) {
				let destination = (destination as! UINavigationController).topViewController as! NCNewMailViewController
				destination.recipients = draft?.to ?? recipients ?? []
				destination.subject = draft?.subject ?? subject
				destination.body = draft?.body ?? body
				destination.draft = draft
			}
		}
		
		class Attachments: Route {
			let completionHandler: (NCMailAttachmentsViewController, Any) -> Void
			
			init(completionHandler: @escaping (NCMailAttachmentsViewController, Any) -> Void) {
				self.completionHandler = completionHandler
				super.init(kind: .adaptiveModal, storyboard: UIStoryboard.character, identifier: "NCMailAttachmentsViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCMailAttachmentsViewController
				destination.completionHandler = completionHandler
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
				super.init(kind: .push, storyboard: UIStoryboard.character, identifier: "NCWealthAssetsViewController")
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
				super.init(kind: .push, storyboard: UIStoryboard.business, identifier: "NCContractInfoViewController")
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
				super.init(kind: .push, storyboard: UIStoryboard.character, identifier: "NCEventViewController")
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
				super.init(kind: .push, storyboard: UIStoryboard.killReports, identifier: "NCKillmailInfoViewController")
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
				super.init(kind: .adaptiveModal, storyboard: UIStoryboard.killReports, identifier: "NCZKillboardContactsViewController")
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
				super.init(kind: .popover, storyboard: UIStoryboard.killReports, identifier: "NCZKillboardTypePickerViewController")
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
				super.init(kind: .push, storyboard: UIStoryboard.killReports, identifier: "NCZKillboardGroupsViewController")
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
				super.init(kind: .push, storyboard: UIStoryboard.killReports, identifier: "NCZKillboardTypesViewController")
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

		class ZKillboardReports: Route {
			let filter: [ZKillboard.Filter]
			
			init(filter: [ZKillboard.Filter]) {
				self.filter = filter
				super.init(kind: .push, storyboard: UIStoryboard.killReports, identifier: "NCZKillboardKillmailsViewController")
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
				super.init(kind: .push, storyboard: UIStoryboard.killReports, identifier: "NCZKillboardSummaryViewController")
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
				super.init(kind: .push, storyboard: UIStoryboard.killReports, identifier: "NCZKillboardKillmailsViewController")
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
	
	enum ShoppingList {
		
		class Add: Route {
			let items: [NCShoppingItem]
			init(items: [NCShoppingItem]) {
				self.items = items
				super.init(kind: .adaptiveModal, identifier: "NCShoppingListAdditionViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCShoppingListAdditionViewController
				destination.items = items
			}
		}
	}
	
	enum Account {
		class AccountsFolderPicker: Route {
			let completionHandler: (NCAccountsFolderPickerViewController, NCAccountsFolder?) -> Void
			
			init(completionHandler: @escaping (NCAccountsFolderPickerViewController, NCAccountsFolder?) -> Void) {
				self.completionHandler = completionHandler
				super.init(kind: .popover, identifier: "NCAccountsFolderPickerViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCAccountsFolderPickerViewController
				destination.completionHandler = completionHandler
			}
			
		}

		class Folders: Route {
			
			init() {
				super.init(kind: .popover, identifier: "NCAccountsFolderPickerViewController")
			}
			
		}
	}
	
	enum MainMenu {
		
		class CharacterSheet: Route {
			init() {
				super.init(kind: .detail, storyboard: .character, identifier: "NCCharacterSheetViewController")
			}
		}

		class JumpClones: Route {
			init() {
				super.init(kind: .detail, storyboard: .character, identifier: "NCJumpClonesViewController")
			}
		}

		class Skills: Route {
			init() {
				super.init(kind: .detail, storyboard: .character, identifier: "NCSkillsContainerViewController")
			}
		}

		class Mail: Route {
			init() {
				super.init(kind: .detail, storyboard: .character, identifier: "NCMailContainerViewController")
			}
		}

		class Calendar: Route {
			init() {
				super.init(kind: .detail, storyboard: .character, identifier: "NCCalendarViewController")
			}
		}

		class Wealth: Route {
			init() {
				super.init(kind: .detail, storyboard: .character, identifier: "NCWealthViewController")
			}
		}
		

		class Database: Route {
			init() {
				super.init(kind: .detail, storyboard: .database, identifier: "NCDatabaseCategoriesViewController")
			}
		}

		class Certificates: Route {
			init() {
				super.init(kind: .detail, storyboard: .database, identifier: "NCDatabaseCertificateGroupsViewController")
			}
			
		}
		
		class Market: Route {
			init() {
				super.init(kind: .detail, storyboard: .database, identifier: "NCMarketPageViewController")
			}
			
		}
		
		class NPC: Route {
			init() {
				super.init(kind: .detail, storyboard: .database, identifier: "NCNPCViewController")
			}
			
		}

		class Wormholes: Route {
			init() {
				super.init(kind: .detail, storyboard: .database, identifier: "NCWHViewController")
			}
			
		}

		class Incursions: Route {
			init() {
				super.init(kind: .detail, storyboard: .database, identifier: "NCIncursionsViewController")
			}
		}

		class Fitting: Route {
			init() {
				super.init(kind: .detail, storyboard: .fitting, identifier: "NCFittingMenuViewController")
			}
		}

		class KillReports: Route {
			init() {
				super.init(kind: .detail, storyboard: .killReports, identifier: "NCKillmailsPageViewController")
			}
		}

		class ZKillboardReports: Route {
			init() {
				super.init(kind: .detail, storyboard: .killReports, identifier: "NCZKillboardViewController")
			}
		}

		class Assets: Route {
			init() {
				super.init(kind: .detail, storyboard: .business, identifier: "NCAssetsViewController")
			}
		}

		class MarketOrders: Route {
			init() {
				super.init(kind: .detail, storyboard: .business, identifier: "NCMarketOrdersViewController")
			}
		}

		class Contracts: Route {
			init() {
				super.init(kind: .detail, storyboard: .business, identifier: "NCContractsViewController")
			}
		}

		class WalletTransactions: Route {
			init() {
				super.init(kind: .detail, storyboard: .business, identifier: "NCWalletTransactionsViewController")
			}
		}

		class WalletJournal: Route {
			init() {
				super.init(kind: .detail, storyboard: .business, identifier: "NCWalletJournalViewController")
			}
		}

		class IndustryJobs: Route {
			init() {
				super.init(kind: .detail, storyboard: .business, identifier: "NCIndustryViewController")
			}
		}

		class Planetaries: Route {
			init() {
				super.init(kind: .detail, storyboard: .business, identifier: "NCPlanetaryViewController")
			}
		}
		
		class News: Route {
			init() {
				super.init(kind: .detail, storyboard: .main, identifier: "NCFeedsViewController")
			}
		}

		class Settings: Route {
			init() {
				super.init(kind: .detail, storyboard: .main, identifier: "NCSettingsViewController")
			}
		}

		class About: Route {
			init() {
				super.init(kind: .detail, storyboard: .main, identifier: "NCAboutViewController")
			}
		}

		class LoyaltyPoints: Route {
			init() {
				super.init(kind: .detail, storyboard: .character, identifier: "NCLoyaltyPointsViewController")
			}
		}
		
		class Subscription: Route {
			init() {
				super.init(kind: .detail, storyboard: .main, identifier: "NCSubscriptionViewController")
			}
		}

		class BugReport: Route {
			init() {
				super.init(kind: .adaptiveModal, storyboard: .main, identifier: "NCBugreportViewController")
			}
			
			class Finish: Route {
				let attachments: [String: Data]
				let subject: String
				
				init(attachments: [String: Data], subject: String, kind: RouteKind = .push) {
					self.attachments = attachments
					self.subject = subject
					super.init(kind: kind, storyboard: .main, identifier: "NCBugreportFinishViewController")
				}
				
				override func prepareForSegue(destination: UIViewController) {
					let destination = destination as! NCBugreportFinishViewController
					destination.attachments = attachments
					destination.subject = subject
				}

			}
		}

	}
	
	enum Utility {
		
		class Transfer: Route {
			let loadouts: NCLoadoutRepresentation
			
			init(loadouts: NCLoadoutRepresentation) {
				self.loadouts = loadouts
				super.init(kind: .adaptiveModal, storyboard: .main, identifier: "NCTransferViewController")
			}
			
			override func prepareForSegue(destination: UIViewController) {
				let destination = destination as! NCTransferViewController
				destination.loadouts = loadouts
			}
		}
	}
	
	enum Settings {
		class SkillQueueNotifications: Route {
			init() {
				super.init(kind: .push, storyboard: .main, identifier: "NCSkillQueueNotificationSettingsViewController")
			}
		}
	}
}

private var RouteKey = "currentRoute"

extension UIViewController {
	fileprivate(set) var route: Route? {
		get {
			return objc_getAssociatedObject(self, &RouteKey) as? Route ?? parent?.route
		}
		set {
			objc_setAssociatedObject(self, &RouteKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
}
