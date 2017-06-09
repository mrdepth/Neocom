//
//  NCWealthViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCWealthViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	
	private var pieChartRow: NCPieChartRow?
	private var detailsSection: TreeNode?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		registerRefreshable()
		
		tableView.register([Prototype.NCDefaultTableViewCell.attribute,
		                    Prototype.NCPieChartTableViewCell.default])
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		pieChartRow = NCPieChartRow(formatter: NCUnitFormatter(unit: .isk, style: .short))
		detailsSection = TreeNode()
		
		let root = TreeNode()
		root.children = [pieChartRow!, detailsSection!]
		treeController.content = root
		
		reload()
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.route?.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
	
	//MARK: - NCRefreshable
	
	private var observer: NCManagedObjectObserver?
	private var clones: NCCachedResult<EVE.Char.Clones>?
	private var wallets: NCCachedResult<[ESI.Wallet.Balance]>?
	private var assets: NCCachedResult<[ESI.Assets.Asset]>?
	private var blueprints: NCCachedResult<[ESI.Character.Blueprint]>?
	private var marketOrders: NCCachedResult<EVE.Char.MarketOrders>?
	private var industryJobs: NCCachedResult<EVE.Char.IndustryJobs>?
	private var contracts: NCCachedResult<EVE.Char.Contracts>?
	private var prices: [Int: Double]?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		
		let dispatchGroup = DispatchGroup()
		let progress = Progress(totalUnitCount: 6)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		let observer = NCManagedObjectObserver() { [weak self] (updated, deleted) in
			self?.update()
		}
		self.observer = observer
		
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.clones { result in
				self.clones = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
						self.update()
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
			}
		}
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.wallets { result in
				self.wallets = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
						self.update()
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
			}
		}
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.assets { result in
				self.assets = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
						self.update()
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
			}
		}

		progress.perform {
			dispatchGroup.enter()
			dataManager.blueprints { result in
				self.blueprints = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
				self.update()
			}
		}

		progress.perform {
			dispatchGroup.enter()
			dataManager.marketOrders { result in
				self.marketOrders = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
						self.update()
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
			}
		}

		progress.perform {
			dispatchGroup.enter()
			dataManager.industryJobs { result in
				self.industryJobs = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
						self.update()
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
			}
		}

		progress.perform {
			dispatchGroup.enter()
			dataManager.contracts { result in
				self.contracts = result
				switch result {
				case let .success(_, record):
					if let record = record {
						observer.add(managedObject: record)
						self.update()
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
			}
		}

		dispatchGroup.notify(queue: .main) {
			completionHandler?()
		}
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
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(reloadChart), object: nil)
		perform(#selector(reloadChart), with: nil, afterDelay: 0)
	}
	
	@objc private func reloadChart() {
		guard let characterID = NCAccount.current?.characterID else {return}
		let clones = self.clones?.value
		let wallets = self.wallets?.value
		let assets = self.assets?.value
		let blueprints = self.blueprints?.value
		let marketOrders = self.marketOrders?.value
		let industryJobs = self.industryJobs?.value
		let contracts = self.contracts?.value
		
		gate.perform {
			let group = DispatchGroup()
			
			group.enter()
			
			NCDatabase.sharedDatabase?.performBackgroundTask {context in
				let invTypes = NCDBInvType.invTypes(managedObjectContext: context)

				var implantsIDs = [Int: Int64]()
				
				if let value = clones {
					value.implants?.forEach {_ = (implantsIDs[$0.typeID]? += 1) ?? (implantsIDs[$0.typeID] = 1) }
					value.jumpCloneImplants?.forEach {_ = (implantsIDs[$0.typeID]? += 1) ?? (implantsIDs[$0.typeID] = 1) }
				}
				
				var assetsIDs = [Int: Int64]()

				if let value = assets {
					for asset in value {
						guard let type = invTypes[asset.typeID], type.group?.category?.categoryID != Int32(NCDBCategoryID.blueprint.rawValue) else {continue}
						_ = (assetsIDs[asset.typeID]? += Int64(asset.quantity ?? 1)) ?? (assetsIDs[asset.typeID] = Int64(asset.quantity ?? 1))
					}
				}

				var blueprintsIDs = [Int: (products: [Int: Int64], materials: [Int: Int64])]()

				if let value = blueprints {
					for blueprint in value {
						guard let type = invTypes[blueprint.typeID] else {continue}
						var (products, materials) = blueprintsIDs[blueprint.typeID] ?? ([:], [:])
						if blueprint.runs > 0 {
							if let manufacturing = type.blueprintType?.activities?.first (where: {($0 as? NCDBIndActivity)?.activity?.activityID == 0}) as? NCDBIndActivity {
								for material in manufacturing.requiredMaterials?.allObjects as? [NCDBIndRequiredMaterial] ?? [] {
									guard let typeID = material.materialType?.typeID else {continue}
									
									let count = Int64((Double(material.quantity) * (1.0 - Double(blueprint.materialEfficiency) / 100.0) * 0.85).rounded(.up)) * Int64(blueprint.runs)
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
				
				var ordersIDs = [Int: Int64]()
				var orderBids: Double = 0
				
				if let value = marketOrders {
					for order in value.orders {
						guard order.orderState == .open else {continue}
						if order.bid {
							orderBids += order.price * Double(order.volRemaining)
						}
						else {
							_ = (ordersIDs[order.typeID]? += order.volRemaining) ?? (ordersIDs[order.typeID] = order.volRemaining)
						}
					}
				}

				var industryJobsIDs = [Int: Int64]()
				
				if let value = industryJobs {
					for job in value.jobs {
						guard job.status == .active || job.status == .paused else {continue}
						_ = (industryJobsIDs[job.productTypeID]? += Int64(job.runs)) ?? (industryJobsIDs[job.productTypeID] = Int64(job.runs))
					}
				}

				var contractPrices: Double = 0
				if let value = contracts {
					for contract in value.contractList {
						guard contract.issuerID == characterID, contract.status == .inProgress || contract.status == .outstanding else {continue}
						contractPrices += contract.price
					}
				}
				
				var balance: Double = 0
				wallets?.forEach {balance += Double($0.balance ?? 0) / 100}
				
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
				var blueprints: Double = 0
				var industryJobs: Double = 0
				
				let updateChart = {[weak self] in
					defer {group.leave()}
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
						rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Implants", title: NSLocalizedString("Implants", comment: "").uppercased(), subtitle: NCUnitFormatter.localizedString(from: implants, unit: .isk, style: .full)))
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
							guard let prices = strongSelf.prices, let assets = strongSelf.assets?.value else {return nil}
							return Router.Wealth.Assets(assets: assets, prices: prices)
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

					if blueprints > 0 {
						if (strongSelf.blueprintsSegment?.value = blueprints) == nil {
							strongSelf.blueprintsSegment = PieSegment(value: blueprints, color: UIColor(red: 0, green: 0.5, blue: 1.0, alpha: 1.0), title: NSLocalizedString("Blueprints", comment: ""))
							strongSelf.pieChartRow?.add(segment: strongSelf.blueprintsSegment!)
						}
						rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attribute, nodeIdentifier: "Blueprints", title: NSLocalizedString("Blueprints", comment: "").uppercased(), subtitle: NCUnitFormatter.localizedString(from: blueprints, unit: .isk, style: .full)))
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
				
				if typeIDs.count > 0 {
					NCDataManager().prices(typeIDs: typeIDs) { [weak self] result in
						self?.prices = result
						implantsIDs.forEach({implants += (result[$0.key] ?? 0) * Double($0.value)})
						assetsIDs.forEach({assets += (result[$0.key] ?? 0) * Double($0.value)})
						ordersIDs.forEach({orders += (result[$0.key] ?? 0) * Double($0.value)})
						orders += orderBids
						
						blueprintsIDs: for (_, value) in blueprintsIDs {
							var sum: Double = 0
							for product in value.products {
								guard let price = result[product.key] else {continue blueprintsIDs}
								sum += price * Double(product.value)
							}
							for material in value.materials {
								guard let price = result[material.key] else {continue blueprintsIDs}
								sum += price * Double(material.value)
							}
							blueprints += sum
						}
						
						industryJobsIDs.forEach({industryJobs += (result[$0.key] ?? 0) * Double($0.value)})
						updateChart()
					}
				}
				else {
					DispatchQueue.main.async {
						updateChart()
					}
				}
				
			}
			
			
			group.wait()
		}
	}
	
}
