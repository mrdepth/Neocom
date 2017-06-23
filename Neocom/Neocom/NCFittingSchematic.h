//
//  NCFittingSchematic.h
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCFittingCommodity;
@class NCFittingEngine;

@interface NCFittingSchematic : NSObject
@property (readonly) NSInteger schematicID;
@property (readonly) NSTimeInterval cycleTime;
@property (readonly, nonnull) NCFittingCommodity* output;
@property (readonly, nonnull) NSArray<NCFittingCommodity*>* inputs;
@property (nonatomic, weak, nullable) NCFittingEngine* engine;

- (nonnull instancetype) init NS_SWIFT_UNAVAILABLE("");
- (nonnull instancetype) initWithSchematicID:(NSInteger) schematicID;

@end
