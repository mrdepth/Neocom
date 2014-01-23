//
//  NCCalendarEventCell.h
//  Neocom
//
//  Created by Shimanski Artem on 23.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EVEUpcomingCalendarEventsItem;
@interface NCCalendarEventCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *importantImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventText;
@property (strong, nonatomic) EVEUpcomingCalendarEventsItem* event;
@end
