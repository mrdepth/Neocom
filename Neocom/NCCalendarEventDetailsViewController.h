//
//  NCCalendarEventDetailsViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 23.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCViewController.h"

@class EVEUpcomingCalendarEventsItem;
@interface NCCalendarEventDetailsViewController : NCViewController<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView* webView;
@property (strong, nonatomic) EVEUpcomingCalendarEventsItem* event;
@end
