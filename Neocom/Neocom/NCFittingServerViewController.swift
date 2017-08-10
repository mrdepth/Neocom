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
		
		server["/dropzone.js"] = shareFile(Bundle.main.path(forResource: "dropzone", ofType: "js")!)
		server["/dropzone.css"] = shareFile(Bundle.main.path(forResource: "dropzone", ofType: "css")!)
		server["/main.css"] = shareFile(Bundle.main.path(forResource: "main", ofType: "css")!)
		server["/main.js"] = shareFile(Bundle.main.path(forResource: "main", ofType: "js")!)
		
		server["/loadouts"] = scopes {
			html {
				head {
					base {
						Swifter.target = "_parent"
					}
					meta {
						charset = "utf-8"
					}
					link {
						rel = "stylesheet"
						href = "./main.css"
					}
				}

				body {
					section {
						h1 {
							inner = NSLocalizedString("Neocom II", comment: "")
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
										a {
											href = "/loadout/\(uuid)/dna/"
											div {
												classs = "imageClip"
												img {
													src = "/image/\(row.typeID)"
												}
											}
										}

									}
									td {
										width = "100%"
										a {
											href = "/loadout/\(uuid)/dna/"
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
						div {
							classs = "footer"
							a {
								href = "/loadout/all/xml/loadouts.xml"
								inner = NSLocalizedString("DOWNLOAD ALL", comment: "")
							}
						}
					}
				}
			}
		}
		
		server["/"] = scopes {
			html {
				head {
					meta {
						charset = "utf-8"
					}
					script {
						src = "./dropzone.js"
					}
					link {
						rel = "stylesheet"
						href = "./dropzone.css"
					}
					link {
						rel = "stylesheet"
						href = "./main.css"
					}
				}
				body {
					iframe {
						idd = "content"
						src = "./loadouts"
						onload = "resizeIframe(this)"
					}
					section {
						div {
							idd = "dropzone"
							form {
								idd = "formUpload"
								action = "/upload"
								classs = "dropzone needsclick"
								div {
									classs = "dz-message needsclick"
									p {
										inner = NSLocalizedString("Drop files here or click to upload loadouts.", comment: "")
									}
									span {
										classs = "note needsclick"
										inner = "(EVE-XML and EFT formats are supported)"
									}
								}
							}
						}
						script {
							src = "./main.js"
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
			case "dna":
				let dna: String? = NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext -> String? in
					guard let loadout: NCLoadout = managedObjectContext.fetch("Loadout", where: "uuid == %@", uuid) else {return nil}
					guard let data = loadout.data?.data else {return nil}
					return (NCLoadoutRepresentation.dna([(typeID: Int(loadout.typeID), data: data, name: loadout.name ?? "")]).value as? [String])?.first
				}
				
				if let dna = dna {
					return .movedPermanently("https://o.smium.org/loadout/dna/\(dna)")
				}
			case "eft":
				let eft: String? = NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext -> String? in
					guard let loadout: NCLoadout = managedObjectContext.fetch("Loadout", where: "uuid == %@", uuid) else {return nil}
					guard let data = loadout.data?.data else {return nil}
					return (NCLoadoutRepresentation.eft([(typeID: Int(loadout.typeID), data: data, name: loadout.name ?? "")]).value as? [String])?.first
				}
				
				if let eft = eft {
					return .raw(200, "OK", ["Content-Type" : "application/octet-stream", "Content-Disposition" : "attachment"], { w in
						try? w.write(eft.data(using: .utf8)!)
					})
				}
			case "xml":
				let xml: String? = NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext -> String? in
					if uuid == "all" {
						guard let loadouts: [NCLoadout] = managedObjectContext.fetch("Loadout") else {return nil}
						let array = loadouts.flatMap { loadout -> (typeID: Int, data: NCFittingLoadout, name: String)? in
							guard let data = loadout.data?.data else {return nil}
							return (typeID: Int(loadout.typeID), data: data, name: loadout.name ?? "")
						}
						return NCLoadoutRepresentation.xml(array).value as? String
					}
					else {
						guard let loadout: NCLoadout = managedObjectContext.fetch("Loadout", where: "uuid == %@", uuid) else {return nil}
						guard let data = loadout.data?.data else {return nil}
						return NCLoadoutRepresentation.xml([(typeID: Int(loadout.typeID), data: data, name: loadout.name ?? "")]).value as? String
					}
				}
				
				if let xml = xml {
					return .raw(200, "OK", ["Content-Type" : "application/octet-stream", "Content-Disposition" : "attachment"], { w in
						try? w.write(xml.data(using: .utf8)!)
					})
				}
			default:
				break
			}
			return .movedPermanently("/")
		}

		server.POST["/upload"] = { r in
			guard let multipart = r.parseMultiPartFormData().first else {return .internalServerError}
			let data = Data(bytes: multipart.body)
			
			if let loadouts = NCLoadoutRepresentation(value: data)?.loadouts {
				NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext in
					loadouts.forEach { i in
						let loadout = NCLoadout(entity: NSEntityDescription.entity(forEntityName: "Loadout", in: managedObjectContext)!, insertInto: managedObjectContext)
						loadout.data = NCLoadoutData(entity: NSEntityDescription.entity(forEntityName: "LoadoutData", in: managedObjectContext)!, insertInto: managedObjectContext)
						loadout.typeID = Int32(i.typeID)
						loadout.name = i.name
						loadout.data?.data = i.data
						loadout.uuid = UUID().uuidString
					}
				}
				return HttpResponse.ok(.html(""))
			}
			return HttpResponse.ok(.html(""))
		}
		
		return server
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		textLabel.text = nil
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		do {

			try server.start(80)
			var urls = UIDevice.interfaceAddresses.filter{$0.family == .ipv4}.map{"http://\($0.address)/"}
			if let hostName = UIDevice.hostName {
				urls.insert("http://\(hostName.lowercased())/", at: 0)
			}
			if urls.isEmpty {
				textLabel.text = NSLocalizedString("Unable to determine your IP Address", comment: "")
			}
			else {
				textLabel.attributedText = NSLocalizedString("Open one of the following links", comment: "") + ":\n\n" + urls.joined(separator: "\n") * [NSForegroundColorAttributeName: UIColor.caption]
			}
		}
		catch {
			do {
				try server.start(8080)
				var urls = UIDevice.interfaceAddresses.filter{$0.family == .ipv4}.map{"http://\($0.address):8080/"}
				if let hostName = UIDevice.hostName {
					urls.insert("http://\(hostName.lowercased()):8080/", at: 0)
				}

				if urls.isEmpty {
					textLabel.text = NSLocalizedString("Unable to determine your IP Address", comment: "")
				}
				else {
					textLabel.attributedText = NSLocalizedString("Open one of the following links", comment: "") + ":\n\n" + urls.joined(separator: "\n") * [NSForegroundColorAttributeName: UIColor.caption]
				}
			}
			catch {
				textLabel.text = error.localizedDescription
			}
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
					                   fileName: "\(type.typeName ?? "") - \(loadout.name?.isEmpty == false ? loadout.name! : type.typeName ?? "")"))
					groups[key] = section
				}
			}
			
			return groups.sorted(by: { $0.key < $1.key}).map {
				Section(rows: $0.value.sorted {$0.typeName < $1.typeName}, title: $0.key.uppercased())
			}
		} ?? []
	}
}

