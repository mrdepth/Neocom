//
//  NSArray+Neocom.h
//  Neocom
//
//  Created by Shimanski Artem on 19.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NSArrayTransitionInsertKey @"NSArrayTransitionInsertKey"
#define NSArrayTransitionDeleteKey @"NSArrayTransitionDeleteKey"
#define NSArrayTransitionMoveKey @"NSArrayTransitionMoveKey"

@interface NSArray (Neocom)

- (NSArray*) arrayGroupedByKey:(NSString*) keyPath;

- (NSDictionary*) transitionFromArray:(NSArray*) from;

@end
