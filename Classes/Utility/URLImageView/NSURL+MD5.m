//
//  NSURL+MD5.m
//  URLImageView
//
//  Created by Artem Shimanski on 11/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSURL+MD5.h"
#import "NSString+MD5.h"

@implementation NSURL(MD5)

- (NSString*) md5 {
	return [[self absoluteString] md5];
}

@end
