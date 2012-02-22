//
//  NSArray+GroupBy.h
//  EVEUniverse
//
//  Created by Shimanski on 8/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray(GroupBy)

- (NSArray*) arrayGroupedByKey:(NSString*) keyPath;

@end
