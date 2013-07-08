//
//  RSSViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RSSViewController.h"
#import "RSS.h"
#import "Globals.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIAlertView+Error.h"

@implementation RSSViewController

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Browser", nil);
	NSMutableString *htmlString = [NSMutableString stringWithFormat:@"<a href=\"%@\">%@</a><br>%@<br>", [self.rss.link absoluteString], self.rss.title, self.rss.description];
	if (self.rss.enclosure && self.rss.enclosure.url) {
		//NSString *url = [rss.enclosure valueForKey:@"url"];
		[htmlString appendFormat:@"<br><a href=\"%@\"><img width=16 height=16 src=\"%@\"/>Play %@ (%.1f Mb)</a><br>",
		@"dummy://play",
		 [[[NSBundle mainBundle] URLForResource:((RETINA_DISPLAY) ? @"buttonPlay@2x" : @"buttonPlay") withExtension:@"png"] absoluteString],
		 [[self.rss.enclosure.url absoluteString] lastPathComponent],
		 self.rss.enclosure.length / (1024.0 * 1024.0)];
	}
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		[htmlString appendString:@"<br><br>"];
	[self.webView loadHTMLString:htmlString baseURL:self.rss.link];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
	[self setSafariButton:nil];
    [super viewDidUnload];
	self.webView = nil;
	self.activityIndicatorView = nil;
	self.backButton = nil;
	self.forwardButton = nil;
	self.reloadButton = nil;
}


- (IBAction) onClose:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)onSafari:(id)sender {
	[[UIApplication sharedApplication] openURL:self.rss.link];
}

#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)aWebView {
	self.backButton.enabled = self.webView.canGoBack;
	self.forwardButton.enabled = self.webView.canGoForward;
	[self.activityIndicatorView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
	self.backButton.enabled = self.webView.canGoBack;
	self.forwardButton.enabled = self.webView.canGoForward;
	[self.activityIndicatorView stopAnimating];
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if ([[[request URL] scheme] isEqualToString:@"dummy"]) {
		MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:self.rss.enclosure.url];
		[self presentMoviePlayerViewControllerAnimated:controller];
		return NO;
	}
	else {
		if (navigationType != UIWebViewNavigationTypeOther) {
			[aWebView setScalesPageToFit:YES];
			self.reloadButton.enabled = YES;
		}
		return YES;
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[self.activityIndicatorView stopAnimating];
	[[UIAlertView alertViewWithError:error] show];
}

@end
