//
//  Globals.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Globals.h"


@implementation Globals

+ (NSString*) documentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString*) cachesDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
}


+ (NSString*) accountsFilePath {
	return [[Globals documentsDirectory] stringByAppendingPathComponent:@"accounts.plist"];
}

+ (NSString*) fitsFilePath {
	return [[Globals documentsDirectory] stringByAppendingPathComponent:@"fits.plist"];
}

+ (EVEUniverseAppDelegate*) appDelegate {
	return (EVEUniverseAppDelegate*) [[UIApplication sharedApplication] delegate];
}

@end
