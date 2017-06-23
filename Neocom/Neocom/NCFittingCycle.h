//
//  NCFittingCycle.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCFittingEngine;

@interface NCFittingCycle : NSObject
@property (readonly) NSTimeInterval launchTime;
@property (readonly) NSTimeInterval cycleTime;
@property (nonatomic, weak, nullable) NCFittingEngine* engine;

- (nonnull instancetype) init NS_SWIFT_UNAVAILABLE("");

@end
