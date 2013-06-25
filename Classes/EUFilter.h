//
//  EUFilter.h
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUFilterItem.h"

@interface EUFilter : NSObject<NSCopying>
@property (nonatomic, retain) NSMutableArray *filters;

+ (id) filterWithContentsOfURL:(NSURL*) url;
- (id) initWithContentsOfURL:(NSURL*) url;
- (void) updateWithValues:(NSArray*) values;
- (void) updateWithValue:(id) value;
- (NSArray*) applyToValues:(NSArray*) values;
- (NSPredicate*) predicate;


@end
