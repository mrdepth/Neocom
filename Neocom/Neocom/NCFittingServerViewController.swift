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
							"a {color: white;}" +
							"tr:hover {background-color: #263740;}" +
							"tr {border-bottom: 1px solid #263740;}" +
							"td {padding-left: 8px;padding-top: 4px;padding-bottom: 4px;white-space:nowrap;}" +
						"th {background-color: #141d21;text-align: left;padding-top: 16px;padding-bottom: 4px;color:\(UIColor.lightGray.css);font-weight: normal;font-size: 0.875em;}" +
							"div {width: 32px;height: 32px;border-radius: 8px;position:relative;overflow:hidden;}" +
							"img{position:absolute;width: 100%;height: 100%;left:-50%; right:-50%; top:0;margin:auto;}"
					}
				}
				body {
					center {
						h1 {
							inner = NSLocalizedString("Neocom II", comment: "")
						}
					}
					table(self.loadouts.children as? [DefaultTreeSection] ?? []) { section in
						thead {
							th {
								colspan = "4"
								inner = section.title
							}
						}
						tbody(section.children as? [NCLoadoutRow] ?? []) { row in
							tr {
								let uri = row.loadoutID.uriRepresentation().absoluteString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed) ?? ""
								td {
									a {
										href = "/loadout/\(uri)/dna"
										div {
											img {
												src = "/image/\(row.typeID)"
											}
										}
									}
								}
								td {
									a {
										href = "/loadout/\(uri)/dna"
										inner = "\(row.typeName) - \(!row.loadoutName.isEmpty ? row.loadoutName : NSLocalizedString("Unnamed", comment: ""))"
									}
								}
								td {
									a {
										href = "/loadout/\(uri)/eft"
										inner = "EFT"
									}
								}
								td {
									a {
										href = "/loadout/\(uri)/xml"
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
		
		server["/loadout/:loadoutID/:format"] = { r in
			return HttpResponse.ok(HttpResponseBody.html("asdf"))
		}
		
		return server
	}()
	
	let loadouts = NCLoadoutsSection(categoryID: nil)
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
	
}

