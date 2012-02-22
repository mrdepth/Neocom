//
//  NSString+TimeLeft.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(TimeLeft)

+ (NSString*) stringWithTimeLeft:(NSTimeInterval) timeLeft;
+ (NSString*) stringWithTimeLeft:(NSTimeInterval) timeLeft componentsLimit:(NSInteger) componentsLimit;

@end
