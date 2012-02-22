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


@interface BrowserViewController : UIViewController<UIWebViewDelegate> {
	UIWebView *webView;
	UIBarButtonItem *backButton;
	UIBarButtonItem *forwardButton;
	UIActivityIndicatorView *activityIndicatorView;
	NSURL *startPageURL;
	id<BrowserViewControllerDelegate> delegate;
}
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, retain) NSURL *startPageURL;
@property (nonatomic, assign) id<BrowserViewControllerDelegate> delegate;

- (IBAction) onClose:(id) sender;

@end
