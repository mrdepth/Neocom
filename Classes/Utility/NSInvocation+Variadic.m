//
//  NSInvocation+Variadic.m
//  EVEUniverse
//
//  Created by Shimanski on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSInvocation+Variadic.h"


@implementation NSInvocation(Variadic)

+ (NSInvocation *)invocationWithTarget:(id) target selector:(SEL) selector argumentPointers:(void*) arg, ... {
	NSMethodSignature *signature = [target methodSignatureForSelector:selector];
	
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setTarget:target];
	[invocation setSelector:selector];
	
	int n = [signature numberOfArguments];
	
	va_list list;
	va_start(list, arg);
	for (int i = 2; i < n; i++) {
		[invocation setArgument:arg atIndex:i];
		arg = va_arg(list, id);
	}
	va_end(list);
	return invocation;
}

/*+ (NSInvocation *)invocationWithTarget:(id) target selector:(SEL) selector arguments:(id) arg, ... {
	NSMethodSignature *signature = [target methodSignatureForSelector:selector];
	
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setTarget:target];
	[invocation setSelector:selector];
	
	int n = [signature numberOfArguments];
	
	va_list list;
	va_start(list, arg);
	for (int i = 2; i < n; i++) {
		const char *objCType = [signature getArgumentTypeAtIndex:i];
		assert(objCType);
		assert(objCType[0]);
		
		if (objCType[0] == '@' || objCType[1] == '@')
			[invocation setArgument:&arg atIndex:i];
		else {
			NSUInteger size, align;
			NSGetSizeAndAlignment(objCType, &size, &align);
			assert(size);
			void *value = malloc(size);
			assert(value);
			bzero(value, size);
			
			[arg getValue:value];
			[invocation setArgument:value atIndex:i];
			free(value);
		}
		arg = va_arg(list, id);
	}
	va_end(list);
	return invocation;
}*/

@end