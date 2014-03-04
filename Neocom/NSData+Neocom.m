//
//  NSData+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 04.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NSData+Neocom.h"
#import <zlib.h>

@implementation NSData (Neocom)

+ (instancetype) dataWithCompressedContentsOfFile:(NSString *)path {
	gzFile file = gzopen([path UTF8String], "rb");
	if (!file)
		return nil;
	
	char buff[128];
	int len = 0;
	NSMutableData* data = [NSMutableData new];
	while ((len = gzread(file, buff, sizeof(buff))) > 0)
		[data appendBytes:buff length:len];
	gzclose(file);
	return data;
}

- (NSData*) uncompressedData {
	Bytef dest[128] = {0};
	uLongf destLen = 128;
	z_stream strm = {0};
	strm.next_in = (Bytef*) [self bytes];
	strm.avail_in = [self length];
	strm.next_out = dest;
	strm.avail_out = destLen;
    int ret = inflateInit2(&strm, (15 + 32));
	
	NSMutableData* data = [NSMutableData new];

	if (ret == Z_OK) {
		do {
			strm.avail_out = destLen;
			strm.next_out = dest;
			ret = inflate(&strm, Z_NO_FLUSH);
			if (ret == Z_OK) {
				[data appendBytes:dest length:destLen - strm.avail_out];
			}
			else if (ret == Z_STREAM_END) {
				[data appendBytes:dest length:destLen - strm.avail_out];
				break;
			}
			else
				break;
		}
		while (1);
		inflateEnd(&strm);
	}
	
	return data.length > 0 ? data : self;
}

@end
