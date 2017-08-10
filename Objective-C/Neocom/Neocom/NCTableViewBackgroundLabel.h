//
//  NCTableViewBackgroundLabel.h
//  Neocom
//
//  Created by Artem Shimanski on 18.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCLabel.h"

@interface NCTableViewBackgroundLabel : NCLabel

+ (instancetype) labelWithText:(NSString*) text;
- (instancetype) initWithText:(NSString*) text;

@end
