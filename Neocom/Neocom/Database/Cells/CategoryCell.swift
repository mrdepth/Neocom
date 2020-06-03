//
//  CategoryCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/28/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible

struct CategoryCell: View {
    var category: SDEInvCategory
    var body: some View {
        HStack {
            Icon(category.image).cornerRadius(4)
            Text(category.categoryName ?? "")
        }
    }
}

struct CategoryCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            CategoryCell(category: (try! Storage.sharedStorage.persistentContainer.viewContext.from(SDEInvCategory.self).first())!)
        }.listStyle(GroupedListStyle())
    }
}
