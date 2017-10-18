//
//  NCCalendarEventCell.h
//  Neocom
//
//  Created by Shimanski Artem on 23.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@class EVEUpcomingCalendarEventsItem;
@interface NCCalendarEventCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *importantImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventTextLabel;
@property (strong, nonatomic) EVEUpcomingCalendarEventsItem* event;
@end
