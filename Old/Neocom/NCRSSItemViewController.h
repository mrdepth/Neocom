//
//  NCRSSItemViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 05.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RSSItem;
@interface NCRSSItemViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView* webView;
@property (nonatomic, strong) RSSItem* rss;

@end
