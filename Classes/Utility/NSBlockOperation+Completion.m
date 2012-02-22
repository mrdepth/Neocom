//
//  NSBlockOperation+Completion.m
//  EVEUniverse
//
//  Created by Shimanski on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSBlockOperation+Completion.h"


@implementation NSBlockOperation(Completion)

- (void) setCompletionBlockInCurrentThread:(void (^)(void))block {
	dispatch_queue_t queue = dispatch_get_current_queue();
	[self setCompletionBlock:^(void) {
		if (dispatch_get_current_queue() == queue)
			block();
		else
			dispatch_sync(queue, block);
	}];
}

@end
