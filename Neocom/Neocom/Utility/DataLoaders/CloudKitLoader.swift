//
//  CloudKitLoader.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/7/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import CloudKit

class CloudKitLoader: ObservableObject {
    @Published var isLoading = true
    @Published var records: [CKRecord] = []
    @Published var error: Error?
    
    @Atomic private var partialResult: [CKRecord] = []
    
    private func didReceive(_ record: CKRecord) {
        partialResult.append(record)
    }
    
    private func didFinish(_ cursor: CKQueryOperation.Cursor?, _ error: Error?) {
        if let cursor = cursor {
            let operation = CKQueryOperation(cursor: cursor)
            operation.recordFetchedBlock = didReceive
            operation.queryCompletionBlock = didFinish
            database.add(operation)
        }
        else {
            DispatchQueue.main.async {
                self.records += self.partialResult
                self.isLoading = false
                self.error = error
            }
        }
    }
    
    private var database: CKDatabase
    
    init(_ database: CKDatabase, query: CKQuery) {
        self.database = database
        
        let operation = CKQueryOperation(query: query)
        operation.recordFetchedBlock = didReceive
        operation.queryCompletionBlock = didFinish
        database.add(operation)
    }
}

