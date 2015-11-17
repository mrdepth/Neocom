//
//  NSCache+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 18.08.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCache (Neocom)

- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)aKey;
- (id) objectForKeyedSubscript:(id)key;

@end
