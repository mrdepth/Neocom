//
//  ActivityView.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/8/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> ActivityViewWrapper {
        ActivityViewWrapper(activityItems: activityItems, applicationActivities: applicationActivities, isPresented: $isPresented)
    }
    
    func updateUIViewController(_ uiViewController: ActivityViewWrapper, context: Context) {
        uiViewController.activityItems = activityItems
        uiViewController.applicationActivities = applicationActivities
        uiViewController.isPresented = $isPresented
        uiViewController.updateState()
    }
}

class ActivityViewWrapper: UIViewController {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]?
    
    var isPresented: Binding<Bool>
    
    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil, isPresented: Binding<Bool>) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.isPresented = isPresented
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        updateState()
    }
    
    fileprivate func updateState() {
        guard parent != nil else {return}
        let isActivityPresented = presentedViewController != nil
        if isActivityPresented != isPresented.wrappedValue {
            if !isActivityPresented {
                let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
                controller.completionWithItemsHandler = { (activityType, completed, _, _) in
                    self.isPresented.wrappedValue = false
                }
                controller.modalPresentationStyle = .popover
                controller.popoverPresentationController?.sourceView = self.view
                controller.popoverPresentationController?.sourceRect = self.view.bounds
                DispatchQueue.main.async {
                    self.present(controller, animated: true, completion: nil)
                }
            }
            else {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}

struct ActivityViewTest: View {
    @State private var isActivityPresented = false
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.self) private var environment
    @Environment(\.managedObjectContext) private var managedObjectContext

    var body: some View {
        let ship = Ship(typeID: 645, modules: [.hi: [Ship.Module(typeID: 35928)]])
//        let data = try? LoadoutPlainTextEncoder(managedObjectContext: managedObjectContext).encode(ship)
//        let text = String(data: data!, encoding: .utf8)
        let loadout = LoadoutActivityItem(ships: [ship, ship], managedObjectContext: managedObjectContext)
        return Button("Present") {
            self.isActivityPresented = true
        }.background(ActivityView(activityItems: [loadout], applicationActivities: [InGameActivity(environment: environment, sharedState: sharedState)], isPresented: $isActivityPresented))
    }
}

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityViewTest()
            .environmentObject(SharedState.testState())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())

    }
}
