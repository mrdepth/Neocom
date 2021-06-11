//
//  LanguagePackCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Combine

struct LanguagePackCell: View {
    
    @ObservedObject var resource: BundleResource
    @EnvironmentObject var storage: Storage
    @State private var error: IdentifiableWrapper<Error>?
    var onSelect: ((BundleResource) -> Void)? = nil

    private func title(_ pack: LanguagePack) -> some View {
        VStack(alignment: .leading) {
            Text(pack.name).foregroundColor(.primary)
            pack.localizedName.modifier(SecondaryLabelModifier())
        }
    }

    private func select() {
        if resource.availability == .unavailable {
            if resource.progress == nil {
                download()
            }
            else {
                resource.cancelRequest()
            }
        }
        else if resource.availability == .available {
            self.storage.sde = resource
            self.onSelect?(resource)
        }
    }
    
    private func download() {
        resource.beginAccessingResource { (error) in
            if (error as? CocoaError)?.code != CocoaError.userCancelled {
                self.error = error.map{IdentifiableWrapper($0)}
            }
        }
    }

    var body: some View {
        let pack = LanguagePack.packs[resource.tag]
        
        return pack.map { pack in
            Button(action: select) {
                HStack {
                    title(pack)
                    Spacer()
                    if resource.availability == .unavailable {
                        if resource.progress != nil {
                            DownloadIndicatorButton(progress: resource.progress!) {
                                withAnimation {
                                    self.resource.cancelRequest()
                                }
                            }
                        }
                        else {
                            Image(systemName: "icloud.and.arrow.down")
                        }
                    }
                    if resource.tag == storage.sde.tag {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .alert(item: $error) { error in
                Alert(title: Text("Error"), message: Text(error.wrappedValue.localizedDescription), dismissButton: .cancel(Text("Close")))
            }
        }
    }
}

struct LanguagePackCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            LanguagePackCell(resource: BundleResource(tag: "SDE_ru"))
        }.listStyle(GroupedListStyle())
    }
}
