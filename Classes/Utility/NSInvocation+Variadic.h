//
//  NSInvocation+Variadic.h
//  EVEUniverse
//
//  Created by Shimanski on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSInvocation(Variadic)

+ (NSInvocation *)invocationWithTarget:(id) target selector:(SEL) selector argumentPointers:(void*) arg, ...;
//+ (NSInvocation *)invocationWithTarget:(id) target selector:(SEL) selector arguments:(id) arg, ...;

@end
