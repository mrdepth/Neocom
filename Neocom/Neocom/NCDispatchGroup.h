//
//  NCDispatchGroup.h
//  Neocom
//
//  Created by Artem Shimanski on 17.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCDispatchGroup : NSObject

- (id) enter;
- (void) leave:(id) token;
- (void) notify:(void(^)()) block;
@end
