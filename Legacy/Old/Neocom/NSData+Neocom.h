//
//  NSData+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 04.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Neocom)

+ (instancetype) dataWithCompressedContentsOfFile:(NSString *)path;
- (NSData*) uncompressedData;
- (BOOL)writeCompressedToFile:(NSString *)path;

@end
