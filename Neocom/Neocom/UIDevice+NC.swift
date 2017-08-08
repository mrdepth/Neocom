//
//  UIDevice+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation


struct InterfaceAddress {
	enum Familiy {
		case ipv4
		case ipv6
		
		init?(rawValue: UInt8) {
			switch rawValue {
			case UInt8(AF_INET):
				self = .ipv4
			case UInt8(AF_INET6):
				self = .ipv6
			default:
				return nil
			}
		}
	}

	var address: String
	var family: Familiy
}

extension UIDevice {
	class var interfaceAddresses: [InterfaceAddress] {
		var addresses = [InterfaceAddress]()
		
		var ifaddr : UnsafeMutablePointer<ifaddrs>?
		guard getifaddrs(&ifaddr) == 0 else { return [] }
		guard let firstAddr = ifaddr else { return [] }
		
		for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
			let flags = Int32(ptr.pointee.ifa_flags)
			let addr = ptr.pointee.ifa_addr.pointee
			
			if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
				if let family = InterfaceAddress.Familiy(rawValue: addr.sa_family) {
					var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
					if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
					                nil, socklen_t(0), NI_NUMERICHOST) == 0) {
						let address = String(cString: hostname)
						addresses.append(InterfaceAddress(address: address, family: family))
					}
				}
			}
		}
		
		freeifaddrs(ifaddr)
		return addresses
	}
}
