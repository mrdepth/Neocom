//
//  RSSItem+Neocom.h
//  Neocom
//
//  Created by Артем Шиманский on 05.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <EVEAPI/EVEAPI.h>

@interface RSSItem (Neocom)
@property (nonatomic, strong) NSString* shortDescription;
@property (nonatomic, strong) NSString* plainTitle;
@property (nonatomic, strong) NSString* updatedDateString;
@end
