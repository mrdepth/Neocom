//
//  WalletJournalCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct WalletJournalCell: View {
    var item: ESI.WalletJournal.Element
    
    private var date: some View {
        Text(DateFormatter.localizedString(from: item.date, dateStyle: .none, timeStyle: .medium))
            .modifier(SecondaryLabelModifier())
    }
    
    private var title: some View {
        Text(item.referenceType.title).font(.headline)
    }
    
    private var amount: some View {
        item.amount.map { amount in
            Text(UnitFormatter.localizedString(from: amount, unit: .isk, style: .long))
                .foregroundColor(amount < 0 ? .red : .green)
            
            //                    .modifier(SecondaryLabelModifier())
        }
    }
    
    private var balance: some View {
        item.balance.map { balance in
                Text("Balance: ").fontWeight(.semibold).foregroundColor(.primary) +
                Text(UnitFormatter.localizedString(from: balance, unit: .isk, style: .long))
        }?.modifier(SecondaryLabelModifier())
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                title
                Spacer()
                amount
            }
            balance
            date
        }
        
    }
}

struct WalletJournalCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            WalletJournalCell(item: ESI.Characters.CharacterID.Wallet.Journal.Success(amount: 1000,
                                                              balance: 10000,
                                                              contextID: 1554561480,
                                                              contextIDType: .characterID,
                                                              date: Date(timeIntervalSinceNow: -3600 * 12),
                                                              localizedDescription: "Description",
                                                              firstPartyID: 1554561480,
                                                              id: 1554561480,
                                                              reason: "Reason",
                                                              refType: .agentDonation,
                                                              secondPartyID: 1554561480,
                                                              tax: 10,
                                                              taxReceiverID: 1554561480))
        }.listStyle(GroupedListStyle())
    }
}
