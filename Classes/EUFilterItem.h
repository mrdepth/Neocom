//
//  EUFilterItem.h
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUFilterItemValue.h"

@interface EUFilterItem : NSObject<NSCopying>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *allValue;
@property (nonatomic, copy) NSString *valuePropertyKey;
@property (nonatomic, copy) NSString *titlePropertyKey;
@property (nonatomic, strong) NSMutableSet *values;

+ (id) filterItem;
- (void) updateWithValue:(id) value;
- (NSSet*) selectedValues;
- (NSPredicate*) predicate;

@end