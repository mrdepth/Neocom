//
//  UIDevice+IP.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 4/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIDevice(IP)

+ (NSString*) localIPAddress;
+ (NSArray*) localIPAddresses;
@end
