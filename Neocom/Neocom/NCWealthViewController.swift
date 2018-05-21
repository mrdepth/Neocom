//
//  NCWealthViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCWealthViewController: NCTreeViewController {
	
	private var pieChartRow: NCPieChartRow?
	private var detailsSection: TreeNode?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		
		tableView.register([Prototype.NCDefaultTableViewCell.attribute,
		                    Prototype.NCPieChartTableViewCell.default])
		
		pieChartRow = NCPieChartRow(formatter: NCUnitFormatter(unit: .isk, style: .short))
		detailsSection = TreeNode()
		
		
	}
	
	override func content() -> Future<TreeNode?> {
//		guard let characterID = NCAccount.current?.characterID else { return .init(nil) }
		
		let content = RootNode([pieChartRow!, detailsSection!])
		reload()
		return .init(content)
	}
	
	
	//MARK: - NCRefreshable
	
	private var clones: CachedValue<ESI.Clones.JumpClones>?
	private var implants: CachedValue<[Int]>?
	private var walletBalance: CachedValue<Double>?
	private var assets: [CachedValue<[ESI.Assets.Asset]>]?
	private var blueprints: CachedValue<[ESI.Character.Blueprint]>?
	private var marketOrders: CachedValue<[ESI.Market.CharacterOrder]>?
	private var industryJobs: CachedValue<[ESI.Industry.Job]>?
	private var contracts: CachedValue<[ESI.Contracts.Contract]>?
	private var prices: [Int: Double]?
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		let progress = Progress(totalUnitCount: 7)
		let promise = Promise<[NCCacheRecord]>()
		
		DispatchQueue.global(qos: .utility).async {
			
			let clones = progress.perform {self.dataManager.clones()}
			let implants = progress.perform {self.dataManager.implants()}
			let walletBalance = progress.perform {self.dataManager.walletBalance()}
			let blueprints = progress.perform {self.dataManager.blueprints()}
			let marketOrders = progress.perform {self.dataManager.marketOrders()}
			let industryJobs = progress.perform {self.dataManager.industryJobs()}
			let contracts = progress.perform {self.dataManager.contracts()}

			var assets = [CachedValue<[ESI.Assets.Asset]>]()
			
			clones.then(on: .main) { result in
				self.clones = result
				self.update()
			}
			implants.then(on: .main) { result in
				self.implants = result
				self.update()
			}
			walletBalance.then(on: .main) { result in
				self.walletBalance = result
				self.update()
			}
			blueprints.then(on: .main) { result in
				self.blueprints = result
				self.update()
			}
			marketOrders.then(on: .main) { result in
				self.marketOrders = result
				self.update()
			}
			industryJobs.then(on: .main) { result in
				self.industryJobs = result
				self.update()
			}
			contracts.then(on: .main) { result in
				self.contracts = result
				self.update()
			}

			for i in 1...20 {
				guard let page = try? progress.perform(block: {self.dataManager.assets(page: i)}).get() else {break}
				guard page.value?.isEmpty == false else {break}
				assets.append(page)
			}
			progress.completedUnitCount += 1
			DispatchQueue.main.async {
				self.assets = assets
				self.update()
			}
			
			clones.wait()
			implants.wait()
			walletBalance.wait()
			blueprints.wait()
			marketOrders.wait()
			industryJobs.wait()
			contracts.wait()
		}.finally(on: .main) {
			var records = [self.clones?.cacheRecord(in: NCCache.sharedCache!.viewContext),
						   self.implants?.cacheRecord(in: NCCache.sharedCache!.viewContext),
						   self.walletBalance?.cacheRecord(in: NCCache.sharedCache!.viewContext),
						   self.blueprints?.cacheRecord(in: NCCache.sharedCache!.viewContext),
						   self.marketOrders?.cacheRecord(in: NCCache.sharedCache!.viewContext),
						   self.industryJobs?.cacheRecord(in: NCCache.sharedCache!.viewContext),
						   self.contracts?.cacheRecord(in: NCCache.sharedCache!.viewContext)].compactMap {$0}
			records.append(contentsOf: self.assets?.map {$0.cacheRecord(in: NCCache.sharedCache!.viewContext)} ?? [])
			try! promise.fulfill(records)
		}
		
		return promise.future
	}
	
	private lazy var gate = NCGate()
	
	private var walletsSegment: PieSegment?
	private var implantsSegment: PieSegment?
	private var assetsSegment: PieSegment?
	private var blueprintsSegment: PieSegment?
	private var marketOrdersSegment: PieSegment?
	private var industryJobsSegment: PieSegment?
	private var contractsSegment: PieSegment?
	
	private func update() {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(internalUpdate), object: nil)
		perform(#selector(internalUpdate), with: nil, afterDelay: 0.15)
	}
	
	@objc private func internalUpdate() {
		if treeController?.content == nil {
			updateContent()
		}
		else {
			reload()
		}
	}

	private func reload() {
		guard let characterID = NCAccount.current?.characterID else { return }
		
		let clones = self.clones?.value
		let activeImplants = self.implants?.value
		let walletBalance = self.walletBalance?.value
		let assets = self.assets?.compactMap{$0.value}.joined()
		let blueprints = self.blueprints?.value
		let marketOrders = self.marketOrders?.value
		let industryJobs = self.industryJobs?.value
		let contracts = self.contracts?.value
		
		NCDatabase.sharedDatabase!.performBackgroundTask { context in
			let invTypes = NCDBInvType.invTypes(managedObjectContext: context)
			
			var implantsIDs = [Int: Int64]()
			
			if let value = clones {
				value.jumpClones.forEach {
					$0.implants.forEach {
						implantsIDs[$0, default: 0] += 1
					}
				}
			}
			activeImplants?.forEach {
				implantsIDs[$0, default: 0] += 1
			}
			
			var assetsIDs = [Int: Int64]()
			var assetsArray = [ESI.Assets.Asset]()
			if let value = assets {
				var types = [Int: NCDBInvType]()
				for asset in value {
					guard asset.locationFlag != .skill && asset.locationFlag != .implant else {continue}
					let t: NCDBInvType? = {
						if let t = types[asset.typeID] {
							return t
						}
						else if let t = invTypes[asset.typeID] {
							types[asset.typeID] = t
							return t
						}
						else {
							return nil
						}
					}()
					guard let type = t, type.group?.category?.categoryID != Int32(NCDBCategoryID.blueprint.rawValue) else {continue}
					_ = (assetsIDs[asset.typeID]? += Int64(asset.quantity)) ?? (assetsIDs[asset.typeID] = Int64(asset.quantity))
					assetsArray.append(asset)
				}
			}
			
			var blueprintsIDs = [Int: (products: [Int: Int64], materials: [Int: Int64])]()
			
			if let value = blueprints {
				for blueprint in value {
					guard let type = invTypes[blueprint.typeID] else {continue}
					var (products, materials) = blueprintsIDs[blueprint.typeID] ?? ([:], [:])
					if blueprint.runs > 0 {
						if let manufacturing = type.blueprintType?.activities?.first (where: {($0 as? NCDBIndActivity)?.activity?.activityID == Int32(NCDBIndActivityID.manufacturing.rawValue)}) as? NCDBIndActivity {
							for material in manufacturing.requiredMaterials?.allObjects as? [NCDBIndRequiredMaterial] ?? [] {
								guard let typeID = material.materialType?.typeID else {continue}
								let count = Int64((Double(material.quantity) * (1.0 - Double(blueprint.materialEfficiency) / 100.0) * 1.0).rounded(.up)) * Int64(blueprint.runs)
								_ = (materials[Int(typeID)]? += count) ?? (materials[Int(typeID)] = count)
							}
							
							for product in manufacturing.products?.allObjects as? [NCDBIndProduct] ?? [] {
								guard let typeID = product.productType?.typeID else {continue}
								let c = Int64(product.quantity) * Int64(blueprint.runs)
								_ = (products[Int(typeID)]? += c) ?? (products[Int(typeID)] = c)
							}
							
						}
					}
					else if blueprint.runs < 0 {
						_ = (products[blueprint.typeID]? += 1) ?? (products[blueprint.typeID] = 1)
					}
					
					blueprintsIDs[blueprint.typeID] = (products, materials)
				}
			}
			
			var ordersIDs = [Int: Int]()
			var orderBids: Double = 0
			
			if let value = marketOrders {
				for order in value {
					if order.isBuyOrder == true {
						orderBids += Double(order.price) * Double(order.volumeRemain)
					}
					else {
						_ = (ordersIDs[order.typeID]? += order.volumeRemain) ?? (ordersIDs[order.typeID] = order.volumeRemain)
					}
				}
			}
			
			var industryJobsIDs = [Int: Int64]()
			
			if let value = industryJobs {
				for job in value {
					guard let productTypeID = job.productTypeID, productTypeID != job.blueprintTypeID else {continue}
					guard job.status == .active || job.status == .paused else {continue}
					_ = (industryJobsIDs[productTypeID]? += Int64(job.runs)) ?? (industryJobsIDs[productTypeID] = Int64(job.runs))
				}
			}
			
			var contractPrices: Double = 0
			if let value = contracts {
				for contract in value {
					guard contract.issuerID == Int(characterID), contract.status == .inProgress || contract.status == .outstanding else {continue}
					contractPrices += Double(contract.price ?? 0)
				}
			}
			
			var balance: Double = 0
			balance += Double(walletBalance ?? 0)
			
			var typeIDs = Set<Int>()
			typeIDs.formUnion(implantsIDs.keys)
			typeIDs.formUnion(assetsIDs.keys)
			typeIDs.formUnion(ordersIDs.keys)
			typeIDs.formUnion(blueprintsIDs.keys)
			typeIDs.formUnion(industryJobsIDs.keys)
			typeIDs.formUnion(blueprintsIDs.map {Set($0.value.materials.map {$0.key}).union($0.value.products.map {$0.key})}.joined())
			
			var implants: Double = 0
			var assets: Double = 0
			var orders: Double = 0
			var blueprintsCost: Double = 0
			var industryJobs: Double = 0
			
			if typeIDs.count > 0 {
				let result = try? NCDataManager().prices(typeIDs: typeIDs).get()
				self.prices = result
				implantsIDs.forEach({implants += (result?[$0.key] ?? 0) * Double($0.value)})
				assetsIDs.forEach({assets += (result?[$0.key] ?? 0) * Double($0.value)})
				ordersIDs.forEach({orders += (result?[$0.key] ?? 0) * Double($0.value)})
				orders += orderBids
				
				blueprintsIDs: for (_, value) in blueprintsIDs {
					var sum: Double = 0
					for product in value.products {
						guard let price = result?[product.key] else {continue blueprintsIDs}
						sum += price * Double(product.value)
					}
					for material in value.materials {
						guard let price = result?[material.key] else {continue blueprintsIDs}
						sum -= price * Double(material.value)
					}
					if sum > 0 {
						blueprintsCost += sum
					}
				}
				
				industryJobsIDs.forEach({industryJobs += (result?[$0.key] ?? 0) * Double($0.value)})
			}
			
			
			DispatchQueue.main.async { [weak self] in
				guard let strongSelf = self else {return}
				var rows: [DefaultTreeRow] = []
				
				if balance > 0 {
					if (strongSelf.walletsSegment?.value = balance) == nil {
						strongSelf.walletsSegment = PieSegment(value: balance, color: .green, title: NSLocalizedString("Account", comment: ""))
						strongSelf.pieChartRow?.add(segment: strongSelf.walletsSegment!)
					}
					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Account", title: NSLocalizedString("Account", comment: "").uppercased(), subtitle: NCUnitFormatter.localizedString(from: balance, unit: .isk, style: .full)))
				}
				else if let segment = strongSelf.walletsSegment {
					strongSelf.pieChartRow?.remove(segment: segment)
				}
				
				if implants > 0 {
					if (strongSelf.implantsSegment?.value = implants) == nil {
						strongSelf.implantsSegment = PieSegment(value: implants, color: UIColor(white: 0.9, alpha: 1.0), title: NSLocalizedString("Implants", comment: ""))
						strongSelf.pieChartRow?.add(segment: strongSelf.implantsSegment!)
					}
					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Implants", title: NSLocalizedString("Implants (clones)", comment: "").uppercased(), subtitle: NCUnitFormatter.localizedString(from: implants, unit: .isk, style: .full)))
				}
				else if let segment = strongSelf.implantsSegment {
					strongSelf.pieChartRow?.remove(segment: segment)
				}
				
				if assets > 0 {
					if (strongSelf.assetsSegment?.value = assets) == nil {
						strongSelf.assetsSegment = PieSegment(value: assets, color: .cyan, title: NSLocalizedString("Assets", comment: ""))
						strongSelf.pieChartRow?.add(segment: strongSelf.assetsSegment!)
					}
					let route: Route? = {
						guard let prices = strongSelf.prices, !assetsArray.isEmpty else {return nil}
						return Router.Wealth.Assets(assets: assetsArray, prices: prices)
					}()
					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute,
											   nodeIdentifier: "Assets",
											   title: NSLocalizedString("Assets", comment: "").uppercased(),
											   subtitle: NCUnitFormatter.localizedString(from: assets, unit: .isk, style: .full),
											   accessoryType: route == nil ? .none : .disclosureIndicator,
											   route: route))
				}
				else if let segment = strongSelf.assetsSegment {
					strongSelf.pieChartRow?.remove(segment: segment)
				}
				
				if blueprintsCost > 0 {
					if (strongSelf.blueprintsSegment?.value = blueprintsCost) == nil {
						strongSelf.blueprintsSegment = PieSegment(value: blueprintsCost, color: UIColor(red: 0, green: 0.5, blue: 1.0, alpha: 1.0), title: NSLocalizedString("Blueprints", comment: ""))
						strongSelf.pieChartRow?.add(segment: strongSelf.blueprintsSegment!)
					}
					let route = Router.Wealth.Blueprints(blueprints: blueprints ?? [], prices: strongSelf.prices ?? [:])
					
					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Blueprints", title: NSLocalizedString("Blueprints", comment: "").uppercased(), subtitle: NCUnitFormatter.localizedString(from: blueprintsCost, unit: .isk, style: .full), accessoryType: .disclosureIndicator, route: route))
				}
				else if let segment = strongSelf.blueprintsSegment {
					strongSelf.pieChartRow?.remove(segment: segment)
				}
				
				if industryJobs > 0 {
					if (strongSelf.industryJobsSegment?.value = industryJobs) == nil {
						strongSelf.industryJobsSegment = PieSegment(value: industryJobs, color: .red, title: NSLocalizedString("Industry", comment: ""))
						strongSelf.pieChartRow?.add(segment: strongSelf.industryJobsSegment!)
					}
					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Industry", title: NSLocalizedString("Industry", comment: "").uppercased(), subtitle: NCUnitFormatter.localizedString(from: industryJobs, unit: .isk, style: .full)))
				}
				else if let segment = strongSelf.industryJobsSegment {
					strongSelf.pieChartRow?.remove(segment: segment)
				}
				
				if orders > 0 {
					if (strongSelf.marketOrdersSegment?.value = orders) == nil {
						strongSelf.marketOrdersSegment = PieSegment(value: orders, color: .yellow, title: NSLocalizedString("Market", comment: ""))
						strongSelf.pieChartRow?.add(segment: strongSelf.marketOrdersSegment!)
					}
					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Market", title: NSLocalizedString("Market", comment: "").uppercased(), subtitle: NCUnitFormatter.localizedString(from: orders, unit: .isk, style: .full)))
				}
				else if let segment = strongSelf.marketOrdersSegment {
					strongSelf.pieChartRow?.remove(segment: segment)
				}
				
				if contractPrices > 0 {
					if (strongSelf.contractsSegment?.value = contractPrices) == nil {
						strongSelf.contractsSegment = PieSegment(value: contractPrices, color: .orange, title: NSLocalizedString("Contracts", comment: ""))
						strongSelf.pieChartRow?.add(segment: strongSelf.contractsSegment!)
					}
					rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Contracts", title: NSLocalizedString("Contracts", comment: "").uppercased(), subtitle: NCUnitFormatter.localizedString(from: contractPrices, unit: .isk, style: .full)))
				}
				else if let segment = strongSelf.contractsSegment {
					strongSelf.pieChartRow?.remove(segment: segment)
				}
				strongSelf.detailsSection?.children = rows
			}
		}
	}
	
}
