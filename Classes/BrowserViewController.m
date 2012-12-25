//
//  BrowserViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BrowserViewController.h"

@implementation BrowserViewController
@synthesize webView;
@synthesize backButton;
@synthesize forwardButton;
@synthesize activityIndicatorView;
@synthesize startPageURL;
@synthesize delegate;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Add API Key", nil);
	[webView loadRequest:[NSURLRequest requestWithURL:startPageURL]];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.webView = nil;
	self.backButton = nil;
	self.forwardButton = nil;
	self.activityIndicatorView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[webView release];
	[backButton release];
	[forwardButton release];
	[activityIndicatorView release];
	[startPageURL release];
    [super dealloc];
}

- (IBAction) onClose:(id) sender {
	[delegate browserViewControllerDidFinish:self];
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

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[activityIndicatorView stopAnimating];
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
													 message:[error localizedDescription]
													delegate:nil
										   cancelButtonTitle:NSLocalizedString(@"Ok", nil)
										   otherButtonTitles:nil] autorelease];
	[alert show];
}
@end
