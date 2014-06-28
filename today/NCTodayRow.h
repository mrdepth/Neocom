//
//  NCTodayRow.h
//  Neocom
//
//  Created by Артем Шиманский on 28.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCTodayRow : NSObject<NSCoding>
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSDate* skillQueueEndDate;
@end
