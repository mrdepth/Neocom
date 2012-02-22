//
//  NSBlockOperation+Completion.h
//  EVEUniverse
//
//  Created by Shimanski on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSBlockOperation(Completion)

- (void) setCompletionBlockInCurrentThread:(void (^)(void))block;

@end
