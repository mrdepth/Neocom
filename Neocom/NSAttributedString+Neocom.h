//
//  NSAttributedString+Neocom.h
//  Neocom
//
//  Created by Artem Shimanski on 14.02.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (Neocom)
+ (NSAttributedString*) attributedStringWithTotalResources:(float) total usedResources:(float) used unit:(NSString*) unit;
+ (NSAttributedString*) shortAttributedStringWithFloat:(float) value unit:(NSString*) unit;
+ (NSAttributedString*) attributedStringWithTimeLeft:(NSTimeInterval) timeLeft;
+ (NSAttributedString*) attributedStringWithTimeLeft:(NSTimeInterval) timeLeft componentsLimit:(NSInteger) componentsLimit;
+ (NSAttributedString*) attributedStringWithString:(NSString*) string url:(NSURL*) url;

@end
