//
//  NSString+Fitting.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(Fitting)

+ (NSString*) stringWithTotalResources:(float) total usedResources:(float) used unit:(NSString*) unit;
+ (NSString*) stringWithResource:(float) resource unit:(NSString*) unit;

@end
