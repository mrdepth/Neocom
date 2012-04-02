//
//  NSString+EUHTTPServer.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 30.03.12.
//  Copyright (c) 2012 Belprog. All rights reserved.
//



@interface NSString (EUHTTPServer)
- (NSDictionary*) httpHeaderValueFields;
- (NSDictionary*) httpHeaders;
- (NSDictionary*) httpGetArguments;
@end
