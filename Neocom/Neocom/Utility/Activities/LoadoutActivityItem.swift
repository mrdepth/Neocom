//
//  LoadoutActivity.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/8/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import UIKit
import LinkPresentation
import MobileCoreServices
import CoreData
import Expressible

class LoadoutActivityItem: NSObject, UIActivityItemSource {
    let ships: [Ship]
    let managedObjectContext: NSManagedObjectContext
    
    init(ships: [Ship], managedObjectContext: NSManagedObjectContext) {
        self.ships = ships
        self.managedObjectContext = managedObjectContext
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ships.first?.name ?? ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if activityType == .inGame {
            return ships
        }
        else if activityType == .airDrop {
            return try? JSONEncoder().encode(ships)
        }
        else {
            let encoder = LoadoutPlainTextEncoder(managedObjectContext: managedObjectContext)
            let item = ships.compactMap{try? encoder.encode($0)}.compactMap{String(data: $0, encoding: .utf8)}.joined(separator: "\n")
            return item
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "com.shimanski.test.fitting"
    }
    
    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        guard let ship = ships.first else {return nil}
        let metadata = LPLinkMetadata()
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(ship.typeID)).first()
        metadata.imageProvider = (type?.uiImage).map{NSItemProvider(object: $0.resize(CGSize(width: 40, height: 40)))}

        let typeName = type?.typeName ?? ""
        if ships.count > 1 {
            metadata.title = "\(typeName) and \(ships.count - 1) more"
        }
        else {
            let shipName = ship.name?.isEmpty == false ? ship.name: typeName
            metadata.title = "\(typeName), \(shipName ?? "")"
        }
        return metadata
    }
}

extension UIImage {
    func resize(_ newSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let image = UIGraphicsImageRenderer(size: newSize).image { (context) in
            context.cgContext.scaleBy(x: newSize.width / size.width, y: newSize.height / size.height)
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        return image
    }
}
