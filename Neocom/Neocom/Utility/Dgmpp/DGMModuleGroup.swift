//
//  DGMModuleGroup.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp
import Combine
import CoreData

class DGMModuleGroup: ObservableObject {
    var modules: [DGMModule] {
        didSet {
            objectWillChange.send()
            subscription = modules.first?.objectWillChange.sink { [weak self] in
                self?.objectWillChange.send()
            }
        }
    }
    
    var objectWillChange = ObservableObjectPublisher()
    
    init<T: Collection>(_ modules: T) where T.Element == DGMModule {
        self.modules = Array(modules)
        assert(!modules.isEmpty)
        subscription = self.modules.first?.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
    private var subscription: AnyCancellable?
    
    var typeID: DGMTypeID {
        modules.first?.typeID ?? 0
    }
    
    var parent: DGMType? {
        modules.first?.parent
    }
    
    func canHaveState(_ state: DGMModule.State) -> Bool {
        modules.first?.canHaveState(state) ?? false
    }
    
    
    var availableStates: [DGMModule.State] {
        modules.first?.availableStates ?? []
    }
    
    var state: DGMModule.State {
        get {
            modules.first?.state ?? .unknown
        }
        set {
            modules.forEach{$0.state = newValue}
        }
    }
    
    var preferredState: DGMModule.State {
        get {
            modules.first?.preferredState ?? .unknown
        }
    }
    
    var target: DGMShip? {
        get {
            modules.first?.target
        }
        set {
            modules.forEach{$0.target = newValue}
        }
    }
    
    var slot: DGMModule.Slot {
        get {
            modules.first?.slot ?? .none
        }
    }

    var hardpoint: DGMModule.Hardpoint {
        get {
            modules.first?.hardpoint ?? .none
        }
    }

    var socket: Int {
        get {
            modules.first?.socket ?? 0
        }
    }
    
    var charge: DGMCharge? {
        modules.first?.charge
    }
    
    func setCharge(_ charge: DGMCharge?) throws {
        if let charge = charge {
            try modules.forEach{try $0.setCharge(DGMCharge(charge))}
        }
        else {
            try modules.forEach{try $0.setCharge(nil)}
        }
    }
    
    func canFit(_ charge: DGMCharge) -> Bool {
        modules.first?.canFit(charge) ?? false
    }
    
    var chargeGroups: [DGMGroupID] {
        modules.first?.chargeGroups ?? []
    }

    var chargeSize: DGMCharge.Size {
        modules.first?.chargeSize ?? .none
    }
    
    var isFail: Bool {
        modules.first?.isFail ?? false
    }

    var requireTarget: Bool {
        modules.first?.requireTarget ?? false
    }

    var reloadTime: TimeInterval {
        modules.first?.reloadTime ?? 0
    }

    var cycleTime: TimeInterval {
        modules.first?.cycleTime ?? 0
    }

    var rawCycleTime: TimeInterval {
        modules.first?.rawCycleTime ?? 0
    }

    var charges: Int {
        modules.first?.charges ?? 0
    }

    var shots: Int {
        modules.first?.shots ?? 0
    }
    
    var capUse: DGMGigaJoulePerSecond {
        modules.first?.capUse ?? DGMGigaJoulePerSecond(0)
    }

    var cpuUse: DGMTeraflops {
        modules.first?.cpuUse ?? 0
    }
    
    var powerGridUse: DGMMegaWatts {
        modules.first?.powerGridUse ?? 0
    }
    
    var calibrationUse: DGMCalibrationPoints {
        modules.first?.calibrationUse ?? 0
    }
    
    var accuracyScore: DGMPoints {
        modules.first?.accuracyScore ?? 0
    }
    
    var signatureResolution: DGMMeter {
        modules.first?.signatureResolution ?? 0
    }
    
    var miningYield: DGMCubicMeterPerSecond {
        modules.first?.miningYield ?? DGMCubicMeterPerSecond(0)
    }

    var volley: DGMDamageVector {
        modules.first?.volley ?? DGMDamageVector.zero
    }
    
    func dps(target: DGMHostileTarget = DGMHostileTarget.default) -> DGMDamagePerSecond {
        modules.first?.dps(target: target) ?? DGMDamagePerSecond(DGMDamageVector.zero)
    }

    var optimal: DGMMeter {
        modules.first?.optimal ?? 0
    }
    
    var falloff: DGMMeter {
        modules.first?.falloff ?? 0
    }
    
    var lifeTime: TimeInterval {
        modules.first?.lifeTime ?? 0
    }

    func angularVelocity(targetSignature: DGMMeter, hitChance: DGMPercent = 0.75) -> DGMRadiansPerSecond {
        modules.first?.angularVelocity(targetSignature: targetSignature, hitChance: hitChance) ?? DGMRadiansPerSecond(0)
    }
    
    func accuracy(targetSignature: DGMMeter, hitChance: DGMPercent = 0.75) -> DGMAccuracy {
        modules.first?.accuracy(targetSignature: targetSignature, hitChance: hitChance) ?? .none
    }
    
    func type(from managedObjectContext: NSManagedObjectContext) -> SDEInvType? {
        modules.first?.type(from: managedObjectContext)
    }
}
