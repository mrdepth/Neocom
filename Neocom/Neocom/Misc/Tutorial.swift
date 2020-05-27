//
//  Tutorial.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/22/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct Tutorial: View {
    var completion: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading) {
                        Text("Welcome to").fontWeight(.bold)
                        Text("Neocom").fontWeight(.bold)
                    }.font(.largeTitle)

                    HStack(spacing: 15) {
                        Image(systemName: "wand.and.rays").resizable().scaledToFit().frame(width: 32, height: 32)
                        VStack(alignment: .leading) {
                            Text("Redesigned").fontWeight(.semibold)
                            Text("Now supports Light/Dark themes.")
                        }
                    }
                    HStack(spacing: 15) {
                        Image(systemName: "desktopcomputer").resizable().scaledToFit().frame(width: 32, height: 32)
                        VStack(alignment: .leading) {
                            Text("More Devices").fontWeight(.semibold)
                            Text("Now available on iPhone, iPad and Mac.")
                        }
                    }
                    HStack(spacing: 15) {
                        Image(systemName: "dot.radiowaves.left.and.right").resizable().scaledToFit().frame(width: 32, height: 32)
                        VStack(alignment: .leading) {
                            Text("Handoff").fontWeight(.semibold)
                            Text("Start edit your loadout on iPhone and continue on Mac.")
                        }
                    }
                    HStack(spacing: 15) {
                        Image(systemName: "doc.plaintext").resizable().scaledToFit().frame(width: 32, height: 32)
                        VStack(alignment: .leading) {
                            Text("Multilanguage").fontWeight(.semibold)
                            Text("Select your preferred language for the EVE Online Database.")
                        }
                    }
                }
                Spacer()
                NavigationLink(destination: TutorialLanguagesPage(completion: completion)) {
                    Text("Continue")//.modifier(TutorialButtonModifier())
                }
            }
            .frame(maxWidth: 375)
            .padding(.horizontal, 25)
            .padding(.bottom, 50)
            .navigationBarItems(leading: BarButtonItems.close(completion))
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct Tutorial_Previews: PreviewProvider {
    static var previews: some View {
        Tutorial {}
    }
}
