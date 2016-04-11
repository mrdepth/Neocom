//
//  GAI+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 11.04.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "GAI+Neocom.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

@implementation GAI (Neocom)

+(void)createScreenWithName:(NSString*) screenName {
	id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
	[tracker set:kGAIScreenName  value:screenName];
	[tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}


@end
