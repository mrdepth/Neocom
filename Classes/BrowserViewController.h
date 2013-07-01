//
//  BrowserViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BrowserViewController;
@protocol BrowserViewControllerDelegate
- (void) browserViewControllerDidFinish:(BrowserViewController*) controller;
@end


@interface BrowserViewController : UIViewController<UIWebViewDelegate>
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) NSURL *startPageURL;
@property (nonatomic, weak) id<BrowserViewControllerDelegate> delegate;

- (IBAction) onClose:(id) sender;

@end
