//
//  UIDevice+IP.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 4/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIDevice+IP.h"
//#include <netinet/in.h>
#include <unistd.h>
#import <arpa/inet.h>
#import <netdb.h>
#include <ifaddrs.h>

@implementation UIDevice(IP)

+ (NSString*) localIPAddress {
	char buf[128];
	bzero(buf, 128);
	gethostname(buf, 128);
	struct hostent *h = NULL;
	h = gethostbyname(buf);
	if (!h)
		return nil;
	struct in_addr *addr = (struct in_addr*) *(h->h_addr_list);
	char *s = inet_ntoa(*addr);
	return [NSString stringWithCString:s encoding:NSASCIIStringEncoding];
}

+ (NSArray*) localIPAddresses {
	NSMutableArray *addresses = [NSMutableArray array];
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	success = getifaddrs(&interfaces);
	if (success == 0) {
		temp_addr = interfaces;
		while(temp_addr != NULL) {
			if(temp_addr->ifa_addr->sa_family == AF_INET) {
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] rangeOfString:@"en"].location == 0) {
					NSString *address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
					[addresses addObject:address];
				}
			}
			temp_addr = temp_addr->ifa_next;
		}
	}
	freeifaddrs(interfaces);
	return addresses;
}

@end
