//
//  NCFittingAttribute.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCFittingItem;
@interface NCFittingAttribute : NSObject
@property (readonly, nonnull) NCFittingItem* owner;
@property (readonly) NSInteger attributeID;
@property (readonly, nonnull) NSString* attributeName;
@property (readonly) double value;
@property (readonly) double initialValue;
@property (readonly) BOOL isStackable;
@property (readonly) BOOL highIsGood;


@end
