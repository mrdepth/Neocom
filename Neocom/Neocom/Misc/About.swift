//
//  About.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct About: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var appVersion: some View {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return HStack {
            Text("Application Version")
            Spacer()
            Text("\(version) (\(build))").foregroundColor(.secondary)
        }
    }
    
    var sdeVersion: some View {
        return HStack {
            Text("SDE")
            Spacer()
            Text(SDEVersion).foregroundColor(.secondary)
        }
    }
    
    func urlCell(title: LocalizedStringKey, url: URL) -> some View {
        Button(action: {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }) {
            VStack(alignment: .leading) {
                Text(title).foregroundColor(.primary)
                Text(url.absoluteString)
            }
        }
    }
    
    var support: some View {
        Button(action: {
            UIApplication.shared.open(URL(string: "mailto:\(Config.current.supportEmail)")!, options: [:], completionHandler: nil)
        }) {
            VStack(alignment: .leading) {
                Text("Support").foregroundColor(.primary)
                Text(Config.current.supportEmail)
            }
        }
    }
    
    var specialThanks: some View {
        let s = ["Ilya Gepp aka Kane Gepp",
                 "Dick Starmans aka Enrique d'Ancourt",
                 "Guy Neale",
                 "Peter Vlaar aka Tess La'Coil",
                 "Wayne Hindle",
                 "Tobias Tango",
                 "Niclas Titius",
                 "Fela Sowande",
                 "Denis Chernov",
                 "Andrei Kokarev",
                 "Kurt Otto"].joined(separator: "\n")
        return Text(s)
    }
    
    var body: some View {
        List {
            Section {
                appVersion
                sdeVersion
            }
            Section {
                support
                urlCell(title: "Homepage", url: Config.current.homepage)
                urlCell(title: "Sources", url: Config.current.sources)
                urlCell(title: "Privacy Policy", url: Config.current.privacy)
                urlCell(title: "Terms of Use", url: Config.current.terms)
            }
            
            Section(header: Text("SPECIAL THANKS")) {
                specialThanks
            }
        }.listStyle(GroupedListStyle())
        .navigationBarTitle("About")
    }
}

struct About_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            About()
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
