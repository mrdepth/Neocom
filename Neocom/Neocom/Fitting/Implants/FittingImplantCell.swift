//
//  FittingImplantCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingImplantCell: View {
    @ObservedObject var implant: DGMImplant
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @State private var isActionsPresented = false

    var body: some View {
        let type = implant.type(from: managedObjectContext)
        return Group {
            HStack {
                Button(action: {self.isActionsPresented = true}) {
                    HStack {
                        if type != nil {
                            TypeCell(type: type!)
                        }
                        else {
                            Icon(Image("implant"))
                            Text("Unknown")
                        }
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
                type.map {
                    TypeInfoButton(type: $0)
                }
            }
        }
        .actionSheet(isPresented: $isActionsPresented) {
            ActionSheet(title: Text("Implant"), buttons: [.destructive(Text("Delete"), action: {
                (self.implant.parent as? DGMCharacter)?.remove(self.implant)
            }), .cancel()])
        }
    }
}

struct FittingImplantCell_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let pilot = gang.pilots[0]
        let implant = pilot.implants.first!

        return NavigationView {
            List {
                FittingImplantCell(implant: implant)
            }.listStyle(GroupedListStyle())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .modifier(ServicesViewModifier.testModifier())
        .environmentObject(gang)

        
    }
}
