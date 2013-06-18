//
//  EUMailMessage.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EVEMailMessagesItem;
@class EUMailBox;
@interface EUMailMessage : NSObject
@property(nonatomic, assign) EUMailBox* mailBox;
@property(nonatomic, retain) NSString* to;
@property(nonatomic, retain) NSString* from;
@property(nonatomic, retain) NSString* text;
@property(nonatomic, retain) NSString* date;
@property(nonatomic, retain) EVEMailMessagesItem* header;
@property(nonatomic, assign, getter = isRead) BOOL read;

+ (id) mailMessageWithMailBox:(EUMailBox*) mailBox;
- (id) initWithMailBox:(EUMailBox*) mailBox;

@end
