//
//  ContentView.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//
#if DEBUG
import SwiftUI
import Combine
import EVEAPI
import CoreData

class A: ObservableObject {
    @Published var i = 10
    
    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.i = 20
        }
    }
}

struct Child: View {
    var body: some View {
        ObservedObjectView(A()) { a in
            Text("a.i = \(a.i)")
            ForEach((0..<a.i).map{$0}, id: \.self) { i in
                Text("\(i)")
            }
        }
    }
}

private struct CustomAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[.top]
    }
}

struct ContentView: View {
    @State var b = false
    @State var l = (0..<10).map{"\($0)"}
    
    
    func f(_ s: String) -> String {
        print(s)
        return s
    }
    
    @State private var isFinished = false
    
    var body: some View {
        let contact1 = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.sharedStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact1.name = "Artem Valiant"
        contact1.contactID = 1554561480
        contact1.category = ESI.RecipientType.character.rawValue

        let attachment = TextAttachmentContact(contact1, esi: ESI())
        
        
        let string = NSMutableAttributedString(string: "Text\n\n\nHello\nHello Wrold")
        string.append(NSAttributedString(attachment: attachment))
        string.append(NSAttributedString(attachment: TextAttachmentContact(contact1, esi: ESI())))
        string.append(NSAttributedString(attachment: TextAttachmentContact(contact1, esi: ESI())))
        string.append(NSAttributedString(string: "Rest text\nBlaBlaBla"))

        
        return ZStack {
//            VStack {
//                VStack(spacing: 0) {
//                    Text("Aloha").alignmentGuide(VerticalAlignment(CustomAlignmentID.self)) {$0[.bottom]}
//                }
//                Text("Hello World")
//                Spacer()
//            }.overlay(Rectangle(), alignment: .init(horizontal: .center, vertical: VerticalAlignment(CustomAlignmentID.self)))
            
//            ComposeMail_Previews.previews
//            TextView(text: .constant(string))

//            TextFieldAlert_Previews.previews
//            SkillPlans_Previews.previews
//            MailBox_Previews.previews
//            NavigationView {
//                NavigationLink("Next", destination: ShipLoadouts())
//            }
//            Home_Previews.previews
            Assets_Previews.previews
//            TextView_Previews.previews
//            LoadingProgressView_Previews.previews
//            NavigationView {
//                TypeCategories()
//            }
            if isFinished {
                FinishedView(isPresented: $isFinished)
            }
        }.onReceive(NotificationCenter.default.publisher(for: .didUpdateSkillPlan)) { _ in
            withAnimation {
                self.isFinished = true
            }
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#endif
