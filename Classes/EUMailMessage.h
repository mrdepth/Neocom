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
@property(nonatomic, weak) EUMailBox* mailBox;
@property(nonatomic, strong) NSString* to;
@property(nonatomic, strong) NSString* from;
@property(nonatomic, strong) NSString* text;
@property(nonatomic, strong) NSString* date;
@property(nonatomic, strong) EVEMailMessagesItem* header;
@property(nonatomic, assign, getter = isRead) BOOL read;

+ (id) mailMessageWithMailBox:(EUMailBox*) mailBox;
- (id) initWithMailBox:(EUMailBox*) mailBox;

@end
