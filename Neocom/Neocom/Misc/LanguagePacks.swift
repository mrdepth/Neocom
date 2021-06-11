//
//  LanguagePacks.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData

struct LanguagePack {
    var name: String
    var localizedName: Text
    
    static let packs = [
        "SDE_en": LanguagePack(name: "English", localizedName: Text("English")),
        "SDE_de": LanguagePack(name: "Deutsch", localizedName: Text("German")),
        "SDE_es": LanguagePack(name: "Español", localizedName: Text("Spanish")),
        "SDE_fr": LanguagePack(name: "Français", localizedName: Text("French")),
        "SDE_it": LanguagePack(name: "Italiano", localizedName: Text("Italian")),
        "SDE_ja": LanguagePack(name: "日本語", localizedName: Text("Japanese")),
        "SDE_ru": LanguagePack(name: "Русский", localizedName: Text("Russian")),
        "SDE_zh": LanguagePack(name: "中文", localizedName: Text("Chinese")),
        "SDE_ko": LanguagePack(name: "한국어", localizedName: Text("Korean")),
    ]
}

struct LanguagePacks: View {
    var onSelect: ((BundleResource) -> Void)? = nil
    private let languagePacks = AppDelegate.sharedDelegate.storage.supportedLanguages() //Storage.testStorage.supportedLanguages()
    
    var body: some View {
        List {
            Section(footer: Text("Tha language of the game database assets (ships, modules, their names and descriptions).")) {
                ForEach(languagePacks , id: \.tag) { pack in
                    LanguagePackCell(resource: pack, onSelect: self.onSelect)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text("Language Pack"))
    }
}

struct LanguagePacks_Previews: PreviewProvider {
    static var previews: some View {
        LanguagePacks()
    }
}

