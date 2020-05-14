//
//  NCMailBoxMessageViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 26.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCViewController.h"

@class NCMailBoxMessage;
@class NCMailBox;
@interface NCMailBoxMessageViewController : NCViewController
@property (weak, nonatomic) IBOutlet UIWebView* webView;
@property (strong, nonatomic) NCMailBoxMessage* message;
@property (strong, nonatomic) NCMailBox* mailBox;
@end
