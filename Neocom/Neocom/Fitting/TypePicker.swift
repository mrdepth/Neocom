//
//  TypePicker.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import CoreData

class TypePickerManager {
    private let typePickerState = Cache<SDEDgmppItemGroup, TypePicker>()
    func get(_ parentGroup: SDEDgmppItemGroup, environment: EnvironmentValues, sharedState: SharedState, completion: @escaping (SDEInvType?) -> Void) -> some View {
        
        let picker = typePickerState[parentGroup, default: TypePicker(content: TypePickerViewController(parentGroup: parentGroup, services: ServicesViewModifier(environment: environment, sharedState: sharedState), completion: {_ in}))]
        picker.content.completion = {
            completion($0)
        }
        return picker.edgesIgnoringSafeArea(.all)
//
//        NavigationView {
//            TypePicker(parentGroup: parentGroup) {
//                completion($0)
//            }
//            .navigationBarItems(leading: BarButtonItems.close {
//                completion(nil)
//            })
//        }
//        .modifier(ServicesViewModifier(environment: environment, sharedState: sharedState))
//        .environmentObject(typePickerState[parentGroup, default: TypePickerState()])
//        .navigationViewStyle(StackNavigationViewStyle())
    }
}

class TypePickerViewController: UINavigationController {
    var completion: (SDEInvType?) -> Void
    init(parentGroup: SDEDgmppItemGroup, services: ServicesViewModifier, completion: @escaping (SDEInvType?) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        let view = TypePickerWrapper(parentGroup: parentGroup) { [weak self] type in
            self?.completion(type)
        }.modifier(services)
        viewControllers = [UIHostingController(rootView: view)]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

struct TypePicker: UIViewControllerRepresentable {
    var content: TypePickerViewController

    func makeUIViewController(context: Context) -> TypePickerViewController {
        return content
    }
    
    func updateUIViewController(_ uiViewController: TypePickerViewController, context: Context) {
    }
}

struct TypePickerWrapper: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var parentGroup: SDEDgmppItemGroup
    var completion: (SDEInvType?) -> Void

    var body: some View {
        TypePickerPage(parentGroup: parentGroup) {
            self.completion($0)
        }.navigationBarItems(leading: BarButtonItems.close {
            self.completion(nil)
        })
    }
}

struct TypePickerPage: View {
    var parentGroup: SDEDgmppItemGroup
    var completion: (SDEInvType) -> Void

    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var selectedGroup: SDEDgmppItemGroup?
    
    var body: some View {
        Group {
            if (parentGroup.subGroups?.count ?? 0) > 0 {
                TypePickerGroups(parentGroup: parentGroup, completion: completion, selectedGroup: $selectedGroup)
            }
            else {
                TypePickerTypes(parentGroup: parentGroup, completion: completion)
            }
        }
    }
}

struct TypePicker_Previews: PreviewProvider {
    static var previews: some View {
        let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
        let group = try! context.fetch(SDEDgmppItemGroup.rootGroup(categoryID: .ship)).first!
        return TypePicker(content: TypePickerViewController(parentGroup: group, services: ServicesViewModifier(managedObjectContext: context, backgroundManagedObjectContext: context, sharedState: SharedState(managedObjectContext: context)), completion: {_ in})).edgesIgnoringSafeArea(.all)
    }
}
