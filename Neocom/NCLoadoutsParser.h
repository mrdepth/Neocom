//
//  NCLoadoutsParser.h
//  Neocom
//
//  Created by Артем Шиманский on 24.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCLoadoutsParser : NSObject

+ (NSArray*) parserEveXML:(NSString*) xml;

@end
