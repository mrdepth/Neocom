//
//  InGameActivity.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/8/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine
import EVEAPI
import Alamofire

extension UIActivity.ActivityType {
    static let inGame = UIActivity.ActivityType(rawValue: "\(bundleID).fitting")
}

class InGameActivity: UIActivity {
    var environment: EnvironmentValues
    var sharedState: SharedState
    
    init(environment: EnvironmentValues, sharedState: SharedState) {
        self.environment = environment
        self.sharedState = sharedState
    }
    
    override class var activityCategory: UIActivity.Category {
//        .share
        .action
    }
    
    override var activityType: UIActivity.ActivityType? {
        .inGame
    }
    
    override var activityTitle: String? {
        NSLocalizedString("Save In-Game", comment: "")
    }
    
    override var activityImage: UIImage? {
        UIImage(named: "eveLogo")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        true
//        return true
//        activityItems.contains {$0 is [Ship]}
    }

    private var ships: [Ship]?
    override func prepare(withActivityItems activityItems: [Any]) {
        self.ships = Array(activityItems.compactMap{$0 as? [Ship]}.joined())
    }
    
    override var activityViewController: UIViewController? {
        guard let ships = self.ships, !ships.isEmpty else {return nil}
        let view = InGameActivityView(ships: ships) { completed in
            self.activityDidFinish(completed)
        }
        .modifier(ServicesViewModifier(environment: environment, sharedState: sharedState))
        
        return UIHostingController(rootView: view)
    }
}

struct InGameActivityView: View {
    var ships: [Ship]
    var completion: (Bool) -> Void
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.managedObjectContext) private var managedObjectContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Account.characterName, ascending: true)])
    private var accounts: FetchedResults<Account>
    
    @State private var savingPublisher: AnyPublisher<Result<Void, AFError>, Never>?
    @State private var error: IdentifiableWrapper<Error>?
    @State private var isFinished = false
    
    private func onSelect(_ account: Account) {
        guard let token = account.oAuth2Token else {return}
        let esi = ESI(token: token)
        savingPublisher = Publishers.Sequence(sequence: ships).map {ESI.MutableFitting($0, managedObjectContext: managedObjectContext)}
            .flatMap { fitting in
                esi.characters.characterID(Int(account.characterID)).fittings().post(fitting: fitting)
        }.collect()
//        let fitting = ESI.MutableFitting(ship, managedObjectContext: managedObjectContext)
//        savingPublisher = esi.characters.characterID(Int(account.characterID)).fittings().post(fitting: fitting)
//        savingPublisher = Just(1).setFailureType(to: AFError.self)
//            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .map{_ in}
            .asResult()
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    private func cell(for account: Account) -> some View {
        Button(action: {
            self.onSelect(account)
        }) {
            HStack {
                Avatar(characterID: account.characterID, size: .size256).frame(width: 40, height: 40)
                Text(account.characterName ?? "")
                Spacer()
            }.contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        var accounts = Array(self.accounts)
        if let account = sharedState.account, let i = accounts.firstIndex(of: account) {
            accounts.remove(at: i)
        }
        
        return NavigationView {
            ZStack{
                List {
                    if sharedState.account != nil {
                        Section(header: Text("CURRENT")) {
                            self.cell(for: sharedState.account!)
                        }
                    }
                    Section {
                        ForEach(accounts, id: \.objectID) { account in
                            self.cell(for: account)
                        }
                    }
                }
                .listStyle(GroupedListStyle())
                if savingPublisher != nil {
                    ActivityIndicator()
                }
                if isFinished {
                    FinishedView(isPresented: $isFinished)
                }
            }
            .alert(item: self.$error) { error in
                Alert(title: Text("Error"), message: Text(error.wrappedValue.localizedDescription), dismissButton: Alert.Button.cancel(Text("Close")))
            }
            .onReceive(savingPublisher ?? Empty().eraseToAnyPublisher()) { result in
                self.savingPublisher = nil
                
                switch result {
                case .success:
                    withAnimation {
                        self.isFinished = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.completion(true)
                    }
                case let .failure(error):
                    self.error = IdentifiableWrapper(error)
                }
            }
            .navigationBarTitle(Text("Select Account"))
            .navigationBarItems(trailing: BarButtonItems.close {
                self.completion(false)
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#if DEBUG
struct InGameActivity_Previews: PreviewProvider {
    static var previews: some View {
        InGameActivityView(ships: [Ship(typeID: 645)]) {_ in}
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environmentObject(SharedState.testState())
    }
}
#endif
