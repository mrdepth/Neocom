//
//  NCFittingEngine.h
//  Neocom
//
//  Created by Artem Shimanski on 18.09.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "eufe.h"

@class NCDBInvType;
@interface NCFittingEngine : NSObject
@property (nonatomic, assign, readonly) eufe::Engine* engine;

- (void)performBlockAndWait:(void (^)())block;
- (NCDBInvType*) typeWithItem:(eufe::Item*) item;

@end
