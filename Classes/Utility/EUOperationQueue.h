//
//  EUOperationQueue.h
//  EVEUniverse
//
//  Created by Shimanski on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSBlockOperation+Completion.h"
#import "EUSingleBlockOperation.h"

@interface EUOperationQueue : NSOperationQueue {

}

+ (EUOperationQueue*) sharedQueue;

@end
