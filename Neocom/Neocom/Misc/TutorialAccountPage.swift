//
//  TutorialAccountPage.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/22/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import CoreData

struct TutorialAccountPage: View {
    var completion: () -> Void
    
    
    @State private var token = FileManager.default.ubiquityIdentityToken
    @Environment(\.managedObjectContext) private var managedObjectContext: NSManagedObjectContext
    @EnvironmentObject private var sharedState: SharedState
    
    private func login() {
        let url = OAuth2.authURL(clientID: Config.current.esi.clientID, callbackURL: Config.current.esi.callbackURL, scope: ESI.Scope.all, state: "esi")
        #if targetEnvironment(macCatalyst)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        #else
        UIApplication.shared.openSafari(with: url)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 30) {
            if sharedState.account == nil {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Add your first\nEVE Online Account").font(.title).fontWeight(.bold)
                    Text("If you used Neocom before, you can import your data from iCloud.").font(.title2)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                VStack(spacing: 15) {
                    Divider()
                    NavigationLink(destination: Migration()) {
                        VStack {
                            Text("Migrate legacy data")
                            if token == nil {
                                Text("Please, log in to iCloud Account").font(.caption)
                            }
                        }
                    }.disabled(token == nil)
                    Divider()
                    Button(action: login) {
                        Text("Log In with EVE Online")
                    }
                    AuthorizationAppleIDButton(completion: completion)
                    Divider()
                }
            }
            else {
                Avatar(characterID: sharedState.account!.characterID, size: .size512).frame(width: 128, height: 128)
                VStack(alignment: .center, spacing: 50) {
                    HStack(spacing: 15) {
                        VStack {
                            Text("Welcome").font(.title).fontWeight(.bold)
                            Text(sharedState.account?.characterName ?? "").font(.title).fontWeight(.bold)
                        }
                    }//.frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
                Text("Neocom is ready to use.").font(.largeTitle).lineLimit(1).minimumScaleFactor(0.5)
                Spacer()
                Spacer()
                Spacer()
            }
            //.fixedSize(horizontal: true, vertical: false)
            Button(action: completion) {
                Text("Start Now")//.modifier(TutorialButtonModifier())
            }
        }
        .frame(maxWidth: 375)
        .padding(.horizontal, 25)
        .padding(.bottom, 50)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.NSUbiquityIdentityDidChange)) { (_) in
            self.token = FileManager.default.ubiquityIdentityToken
        }
    }
}

#if DEBUG
struct TutorialAccountPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TutorialAccountPage {}
        }.navigationViewStyle(StackNavigationViewStyle())
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
