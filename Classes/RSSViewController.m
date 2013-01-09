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
@synthesize webView;
@synthesize activityIndicatorView;
@synthesize backButton;
@synthesize forwardButton;
@synthesize reloadButton;
@synthesize rss;

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
	NSMutableString *htmlString = [NSMutableString stringWithFormat:@"<a href=\"%@\">%@</a><br>%@<br>", [rss.link absoluteString], rss.title, rss.description];
	if (rss.enclosure && rss.enclosure.url) {
		//NSString *url = [rss.enclosure valueForKey:@"url"];
		[htmlString appendFormat:@"<br><a href=\"%@\"><img width=16 height=16 src=\"%@\"/>Play %@ (%.1f Mb)</a><br>",
		@"dummy://play",
		 [[[NSBundle mainBundle] URLForResource:((RETINA_DISPLAY) ? @"buttonPlay@2x" : @"buttonPlay") withExtension:@"png"] absoluteString],
		 [[rss.enclosure.url absoluteString] lastPathComponent],
		 rss.enclosure.length / (1024.0 * 1024.0)];
	}
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		[htmlString appendString:@"<br><br>"];
	[webView loadHTMLString:htmlString baseURL:nil];
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
    [super viewDidUnload];
	self.webView = nil;
	self.activityIndicatorView = nil;
	self.backButton = nil;
	self.forwardButton = nil;
	self.reloadButton = nil;
}


- (void)dealloc {
	[webView release];
	[activityIndicatorView release];
	[backButton release];
	[forwardButton release];
	[reloadButton release];
	[rss release];
    [super dealloc];
}

- (IBAction) onClose:(id) sender {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)aWebView {
	backButton.enabled = webView.canGoBack;
	forwardButton.enabled = webView.canGoForward;
	[activityIndicatorView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
	backButton.enabled = webView.canGoBack;
	forwardButton.enabled = webView.canGoForward;
	[activityIndicatorView stopAnimating];
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if ([[[request URL] scheme] isEqualToString:@"dummy"]) {
		MPMoviePlayerViewController *controller = [[[MPMoviePlayerViewController alloc] initWithContentURL:rss.enclosure.url] autorelease];
		[self presentMoviePlayerViewControllerAnimated:controller];
		return NO;
	}
	else {
		if (navigationType != UIWebViewNavigationTypeOther) {
			[aWebView setScalesPageToFit:YES];
			reloadButton.enabled = YES;
		}
		return YES;
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[activityIndicatorView stopAnimating];
	[[UIAlertView alertViewWithError:error] show];
}

@end
