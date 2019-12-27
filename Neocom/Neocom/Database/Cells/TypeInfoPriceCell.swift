//
//  TypeInfoPriceCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/9/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Alamofire
import Combine
import EVEAPI

struct TypeInfoPriceCell: View {
    var type: SDEInvType
    
    init(type: SDEInvType) {
        self.type = type
    }
    
    @ObservedObject private var price = Lazy<DataLoader<ESI.MarketPrice?, AFError>>()

    @Environment(\.esi) private var esi

    private var pricePublisher: AnyPublisher<ESI.MarketPrice?, AFError> {
        let typeID = Int(type.typeID)
        let publisher = esi.markets.prices().get().map {
            $0.first{$0.typeID == typeID}
        }.receive(on: RunLoop.main)
        
        return AnyPublisher(publisher)
    }

    var body: some View {
        let price = self.price.get(initial: DataLoader(pricePublisher))
        let value = price.result?.value??.averagePrice

        return NavigationLink(destination: TypeMarketOrders(type: type)) {
            HStack {
                Icon(Image("priceTotal"))
                VStack(alignment: .leading) {
                    HStack {
                        Text("PRICE").font(.footnote)
                        if price.result == nil {
                            ActivityIndicator(style: .medium)
                        }
                    }
                    if price.result != nil {
                        if value != nil {
                            Text(UnitFormatter.localizedString(from: value!, unit: .isk, style: .long)).font(.footnote).foregroundColor(.secondary)
                        }
                        else if price.result?.error != nil {
                            Text(price.result!.error!).font(.footnote).foregroundColor(.secondary)
                        }
                        else {
                            Text("N/A").font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct TypeInfoPriceCell_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                TypeInfoPriceCell(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!)
            }.listStyle(GroupedListStyle())
        }
    }
}
