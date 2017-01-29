//
//  NCFittingItem.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCFittingTypes.h"

@class NCFittingItem;
@class NCFittingAttribute;
@class NCFittingEngine;
@interface NCFittingAttributes : NSObject

- (nullable NCFittingAttribute*) objectAtIndexedSubscript:(NSInteger) attributeID;

@end

@interface NCFittingItem : NSObject<NSCopying>
@property (readonly) NSInteger typeID;
@property (readonly, nonnull) NSString* typeName;
@property (readonly, nonnull) NSString* groupName;
@property (readonly) NSInteger groupID;
@property (readonly) NSInteger categoryID;
@property (readonly, nullable) NCFittingItem* owner;
@property (readonly, nonnull) NCFittingAttributes* attributes;
@property (nonatomic, weak, nullable) NCFittingEngine* engine;

- (nonnull instancetype) init NS_SWIFT_UNAVAILABLE("");

@end
