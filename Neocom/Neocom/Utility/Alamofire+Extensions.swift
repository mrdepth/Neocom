//
//  Alamofire+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/17/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Alamofire
import Combine

extension NetworkReachabilityManager {
    class func publisher() -> AnyPublisher<NetworkReachabilityStatus, Never> {
        let manager = NetworkReachabilityManager()
        let subject = CurrentValueSubject<NetworkReachabilityStatus, Never>(manager?.status ?? NetworkReachabilityStatus.unknown)
//        let subject = PassthroughSubject<NetworkReachabilityStatus, Never>()
        
        return subject.handleEvents(receiveSubscription: { (_) in
            manager?.startListening(onUpdatePerforming: { [weak subject] (status) in
                subject?.send(status)
            })
        }, receiveCompletion: { (c) in
            manager?.stopListening()
        }, receiveCancel: {
            manager?.stopListening()
            }).eraseToAnyPublisher()
    }
}

extension NetworkReachabilityManager.NetworkReachabilityStatus {
    var isReachable: Bool {
        switch self {
        case .reachable:
            return true
        default:
            return false
        }
    }
}

extension AFError {
    var notConnectedToInternet: Bool {
        guard let error = underlyingError else {return false}
        if let error = error as? AFError {
            return error.notConnectedToInternet
        }
        else {
            return (error as? URLError)?.code == .notConnectedToInternet
        }
    }
}
