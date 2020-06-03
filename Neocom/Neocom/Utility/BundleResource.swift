//
//  BundleResource.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/15/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class BundleResource: ObservableObject {
    enum Availability {
        case unknown
        case unavailable
        case available
    }
    @Published var availability: Availability
    @Published var progress: Progress?
    
    let tag: String
    
    @Atomic private var waitSync: DispatchGroup?
    @Atomic private var resourceAvailable: Bool
    
    init(tag: String) {
        self.tag = tag
        if tag == "SDE_en" {
            _availability = Published(initialValue: .available)
            resourceAvailable = true
        }
        else {
            resourceAvailable = false
            _availability = Published(initialValue: .unknown)
            request = NSBundleResourceRequest(tags: [tag])
            waitSync = DispatchGroup()
            waitSync?.enter()
            request?.conditionallyBeginAccessingResources(completionHandler: { [weak self, waitSync] (available) in
                self?.resourceAvailable = available
                waitSync?.leave()
                self?.waitSync = nil
                DispatchQueue.main.async {
                    self?.availability = available ? .available : .unavailable
                }
            })
        }
    }
    
    func isAvailable() -> Bool {
        waitSync?.wait()
        return resourceAvailable
    }
    
    private var request: NSBundleResourceRequest?
    private var isLoading = false
    
    func beginAccessingResource(completionHandler: @escaping (Error?) -> Void) {
        guard availability != .available else {
            completionHandler(nil)
            return
        }
        guard !isLoading else {return}
        
        var isFinished = false
        isLoading = true
        request?.beginAccessingResources(completionHandler: { (error) in
            isFinished = true
            self.isLoading = false
            self.resourceAvailable = error == nil
            DispatchQueue.main.async {
                withAnimation {
                    self.progress = nil
                }
                if error == nil {
                    self.availability = .available
                }
                else {
                    self.availability = .unavailable
                    self.request = NSBundleResourceRequest(tags: [self.tag])
                }
                completionHandler(error)
            }
        })
        if !isFinished {
            self.progress = request?.progress
        }
    }
    
    func cancelRequest() {
        request?.progress.cancel()
        request = NSBundleResourceRequest(tags: [self.tag])
        self.progress = nil
    }
}
