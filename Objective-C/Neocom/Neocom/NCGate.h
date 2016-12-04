//
//  NCGate.h
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCGate : NSObject
- (void) performBlock:(void(^)()) block;
@end
