//
//  ComposeMailLoadoutsPicker.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/23/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct ComposeMailLoadoutsPicker: View {
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.managedObjectContext) private var managedObjectContext
    private let loadouts = Lazy<LoadoutsLoader, Never>()
    var completion: (Loadout) -> Void
    
    private func onSelect(_ result: LoadoutsList.Result, _ openMode: OpenMode) {
        switch result {
        case let .loadout(objectID):
            let loadout = managedObjectContext.object(with: objectID) as! Loadout
            completion(loadout)
        default:
            break
        }
    }

    var body: some View {
        let loadouts = self.loadouts.get(initial: LoadoutsLoader(.ship, managedObjectContext: backgroundManagedObjectContext))
        return LoadoutsList(loadouts: loadouts, category: .ship, onSelect: onSelect)
    }
}

struct ComposeMailLoadoutsPicker_Previews: PreviewProvider {
    static var previews: some View {
        _ = Loadout.testLoadouts()

        return NavigationView {
            ComposeMailLoadoutsPicker {_ in }
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
