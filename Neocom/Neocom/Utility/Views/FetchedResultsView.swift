//
//  FetchedResultsView.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/27/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData

struct FetchedResultsView<Content: View, Items: ObservableObject>: View {
    @ObservedObject var items: Items
    var content: (Items) -> Content
    
    @inlinable init(_ items: Items, content: @escaping (Items) -> Content) {
        self.items = items
        self.content = content
    }
    
    var body: some View {
        content(items)
    }
}

//struct FetchedResultsView_Previews: PreviewProvider {
//    static var previews: some View {
//        FetchedResultsView()
//    }
//}
