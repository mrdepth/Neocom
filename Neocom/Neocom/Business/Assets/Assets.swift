//
//  Assets.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible
import Combine

struct Assets: View {
    private enum Filter {
        case byLocation
        case byCategory
    }
    
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState
    @ObservedObject var assets = Lazy<AssetsData, Account>()
    @State private var filter = Filter.byLocation
    
    private var filterControl: some View {
        Picker("Filter", selection: $filter) {
            Text("By Location").tag(Filter.byLocation)
            Text("By Category").tag(Filter.byCategory)
        }.pickerStyle(SegmentedPickerStyle())
    }
    
    var body: some View {
        func list(_ results: [AssetsData.LocationGroup]?) -> some View {
            List {
                if results != nil {
                    ForEach(results!, id: \.location.id) { i in
                        Section(header: Text(i.location)) {
                            AssetsListContent(assets: i.assets)
                        }
                    }
                }
                else {
                    Section(header: self.filterControl) {
                        if self.filter == .byLocation {
                            AssetsLocationsContent(assets: assets?.locations?.value ?? [])
                        }
                        else {
                            if assets?.categories?.value != nil {
                                ForEach(assets!.categories!.value!) { category in
                                    (try? self.managedObjectContext.from(SDEInvCategory.self).filter(/\SDEInvCategory.categoryID == category.id).first()).map { invCategory in
                                        NavigationLink(destination: AssetsCategory(category: category)) {
                                            HStack {
                                                Icon(invCategory.image).cornerRadius(4)
                                                VStack(alignment: .leading) {
                                                    Text(invCategory.categoryName ?? "")
                                                    Text("Quantity: \(UnitFormatter.localizedString(from: category.count, unit: .none, style: .long))").modifier(SecondaryLabelModifier())
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }.listStyle(GroupedListStyle())
        }
        
        let assets = sharedState.account.map{self.assets.get($0, initial: AssetsData(esi: sharedState.esi, characterID: $0.characterID, managedObjectContext: backgroundManagedObjectContext))}
        

        return ZStack {
            AssetsSearch(assets: assets?.locations?.value ?? []) { results in
                Group {
                    if assets != nil {
                        list(results).onRefresh(isRefreshing: Binding(assets!, keyPath: \.isLoading)) {
                            assets?.update(cachePolicy: .reloadIgnoringLocalCacheData)
                        }
                    }
                    else {
                        list(results)
                    }
                }
            }
        }
        .navigationBarTitle(Text("Assets"))
        .overlay(Group {
            if assets?.progress != nil && assets!.progress.fractionCompleted < 1 {
                LoadingProgressView(progress: assets!.progress)
            }
        }, alignment: .top)
        .overlay(assets == nil ? Text(RuntimeError.noAccount).padding() : nil)
        .overlay((assets?.locations?.error).map{Text($0)})
        .overlay(assets?.locations?.value?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)

    }
}

fileprivate struct AssetsLocationsContent: View {
    var assets: [AssetsData.LocationGroup]
    var body: some View {
        ForEach(assets, id: \.location.id) { i in
            NavigationLink(destination: AssetsList(i)) {
                VStack(alignment: .leading) {
                    Text(i.location)
                    Text("\(UnitFormatter.localizedString(from: i.count, unit: .none, style: .long)) assets").modifier(SecondaryLabelModifier())
                }
            }
        }
    }
}

fileprivate struct AssetsSearch<Content: View>: View {
    var assets: [AssetsData.LocationGroup]
    var content: ([AssetsData.LocationGroup]?) -> Content
    
    func search(_ string: String) -> AnyPublisher<[AssetsData.LocationGroup]?, Never> {
        return Future { promise in
            let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if string.count < 3 {
                promise(.success(nil))
            }
            else {
                DispatchQueue.global(qos: .utility).async {
                    func filter(_ asset: AssetsData.Asset) -> [AssetsData.Asset] {
                        var result = [AssetsData.Asset]()
                        if asset.typeName.range(of: string, options: .caseInsensitive, range: nil, locale: nil) != nil ||
                            asset.groupName.range(of: string, options: .caseInsensitive, range: nil, locale: nil) != nil ||
                            asset.categoryName.range(of: string, options: .caseInsensitive, range: nil, locale: nil) != nil {
                            result.append(asset)
                        }
                        result += asset.nested.flatMap{filter($0)}
                        return result
                    }
                    let results = self.assets.map {
                        AssetsData.LocationGroup(location: $0.location, assets: Array($0.assets.flatMap{filter($0)}.prefix(100)))
                    }.filter{!$0.assets.isEmpty}
                    promise(.success(results))
                }
            }
        }.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    var body: some View {
        SearchView(initialValue: nil, search: search) { results in
            self.content(results)
        }
    }
}


#if DEBUG
struct Assets_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Assets()
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())

    }
}
#endif
