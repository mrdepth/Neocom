//
//  NCFittingServerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import Swifter
import Darwin
import CoreData

fileprivate struct Section {
	var rows: [Row] = []
	var title: String = ""
}

fileprivate struct Row {
	var uuid: String
	var loadoutName: String?
	var typeID: Int
	var typeName: String
	var fileName: String
}


class NCFittingServerViewController: UIViewController {
	
	@IBOutlet weak var textLabel: UILabel!
	
	lazy var server: HttpServer = {
		let server = HttpServer()
		
		server["/"] = scopes {
			html {
				head {
					meta {
						charset = "utf-8"
					}
					style {
						inner = "body {width: 100%;background-color: \(UIColor.background.css);color:white;}" +
							"table {border-collapse: collapse;background: \(UIColor.cellBackground.css);width:600px;margin-left:auto;margin-right:auto;}" +
							"a {color: \(UIColor.caption.css);}" +
							"tr:hover {background-color: #263740;}" +
							"tr {border-bottom: 1px solid #263740;}" +
							"td {padding-left: 8px;padding-top: 4px;padding-bottom: 4px;white-space:nowrap;}" +
							"th {background-color: #141d21;text-align: left;padding-top: 16px;padding-bottom: 4px;color:\(UIColor.lightGray.css);font-weight: normal;font-size: 0.875em;}" +
							"div {width: 32px;height: 32px;border-radius: 8px;position:relative;overflow:hidden;}" +
							"img{position:absolute;width: 100%;height: 100%;left:-50%; right:-50%; top:0;margin:auto;}" +
							"small{color:\(UIColor.lightGray.css);}" +
						"p{margin: 0;}"
					}
				}
				body {
					center {
						h1 {
							inner = NSLocalizedString("Neocom II", comment: "")
						}
					}
					table(self.loadouts) { section in
						thead {
							th {
								colspan = "4"
								inner = section.title
							}
						}
						tbody(section.rows) { row in
							tr {
								let uuid = row.uuid
								td {
									div {
										img {
											src = "/image/\(row.typeID)"
										}
									}
								}
								td {
									p {
										inner = "\(row.typeName)"
									}
									p {
										small {
											inner = "\(row.loadoutName ?? "")"
										}
									}
									
								}
								td {
									a {
										href = "/loadout/\(uuid)/eft/\(row.fileName).cfg"
										inner = "EFT"
									}
								}
								td {
									a {
										href = "/loadout/\(uuid)/xml/\(row.fileName).xml"
										inner = "XML"
									}
								}
							}
						}
					}
				}
			}
		}
		
		server["/image/:typeID"] = { r in
			return .raw(200, "OK", nil, { w in
				let data: Data? = NCDatabase.sharedDatabase?.performTaskAndWait { context -> Data? in
					guard let s = r.params[":typeID"], let typeID = Int(s) else {return nil}
					guard let type = NCDBInvType.invTypes(managedObjectContext: context)[typeID] else {return nil}
					guard let image = type.icon?.image?.image else {return nil}
					guard let data = UIImagePNGRepresentation(image) else {return nil}
					return data
				}
				if let data = data {
					try? w.write(data)
				}
			})
		}
		
		server["/loadout/:uuid/:format/:name"] = { r in
			guard let uuid = r.params[":uuid"],
				let format = r.params[":format"]
			else {return .movedPermanently("/")}
			
			switch format {
			case "eft":
				let eft: String? = NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext -> String? in
					guard let loadout: NCLoadout = managedObjectContext.fetch("Loadout", where: "uuid == %@", uuid) else {return nil}
					guard let data = loadout.data?.data else {return nil}
					return (NCLoadoutRepresentation.eft([(typeID: Int(loadout.typeID), data: data, name: loadout.name ?? "")]).value as? [String])?.first
				}
				
				if let eft = eft {
					return HttpResponse.raw(200, "OK", ["Content-Type" : "application/octet-stream", "Content-Dispositio" : "attachment"], { w in
						try? w.write(eft.data(using: .utf8)!)
					})
				}
			case "xml":
				let xml: String? = NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext -> String? in
					guard let loadout: NCLoadout = managedObjectContext.fetch("Loadout", where: "uuid == %@", uuid) else {return nil}
					guard let data = loadout.data?.data else {return nil}
					return NCLoadoutRepresentation.xml([(typeID: Int(loadout.typeID), data: data, name: loadout.name ?? "")]).value as? String
				}
				
				if let xml = xml {
					return HttpResponse.raw(200, "OK", ["Content-Type" : "application/octet-stream", "Content-Dispositio" : "attachment"], { w in
						try? w.write(xml.data(using: .utf8)!)
					})
				}
			default:
				break
			}
			return .movedPermanently("/")
		}
		
		return server
	}()
	
//	let loadouts = NCLoadoutsSection(categoryID: nil)
	var ipAddress: String = ""
	
	override func viewDidLoad() {
		super.viewDidLoad()
		textLabel.text = nil
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		do {

			try server.start(8080)
			let urls = UIDevice.interfaceAddresses.filter{$0.family == .ipv4}.map{"http://\($0.address):8080"}
			textLabel.text = urls.isEmpty ? NSLocalizedString("Unable to determine your IP Address", comment: "") : urls.joined(separator: "\n")
		}
		catch {
			textLabel.text = error.localizedDescription
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		server.stop()
	}

	fileprivate var loadouts: [Section] {
		return NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext -> [Section] in
			guard let loadouts: [NCLoadout] = managedObjectContext.fetch("Loadout") else {return []}

			var groups = [String: [Row]]()
			
			NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext in
				let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
				for loadout in loadouts {
					guard let uuid = loadout.uuid else {continue}
					guard let type = invTypes[Int(loadout.typeID)] else {continue}
					guard let name = type.group?.groupName else {continue}
					let key = name
					var section = groups[key] ?? []
					section.append(Row(uuid: uuid,
					                   loadoutName: loadout.name,
					                   typeID: Int(type.typeID),
					                   typeName: type.typeName ?? "",
					                   fileName: "\(type.typeName ?? "") - \(loadout.name?.isEmpty == false ? loadout.name! : NSLocalizedString("Unnamed", comment: ""))"))
					groups[key] = section
				}
			}
			
			return groups.sorted(by: { $0.key < $1.key}).map {
				Section(rows: $0.value.sorted {$0.typeName < $1.typeName}, title: $0.key.uppercased())
			}
		} ?? []
	}
}

