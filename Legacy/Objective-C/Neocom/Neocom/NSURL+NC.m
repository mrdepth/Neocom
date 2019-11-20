//
//  NSURL+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 18.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NSURL+NC.h"

@implementation NSURL (NC)

- (NSDictionary<NSString*, NSString*>*) parameters {
	NSMutableDictionary* parameters = [NSMutableDictionary new];
	for (NSString* component in [self.query componentsSeparatedByString:@"&"]) {
		NSArray* item = [component componentsSeparatedByString:@"="];
		if (item.count == 2) {
			NSString* key = [item[0] stringByRemovingPercentEncoding];
			NSString* value = [item[1] stringByRemovingPercentEncoding];
			if (key.length > 0 && value)
				parameters[key] = value;
		}
	}
	return parameters;
}

@end
