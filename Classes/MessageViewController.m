//
//  MessageViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessageViewController.h"
#import "EUMailBox.h"
#import "EVEOnlineAPI.h"
#import "EUOperationQueue.h"

@implementation MessageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = self.message.header.title;
	NSMutableString* template = [NSMutableString stringWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"mailMessageTemplate" ofType:@"html"]]
																encoding:NSUTF8StringEncoding error:nil];
	[template replaceOccurrencesOfString:@"{subject}" withString:self.message.header.title ? self.message.header.title : @"" options:0 range:NSMakeRange(0, template.length)];
	[template replaceOccurrencesOfString:@"{from}" withString:self.message.from ? self.message.from : @"" options:0 range:NSMakeRange(0, template.length)];
	[template replaceOccurrencesOfString:@"{to}" withString:self.message.to ? self.message.to : @""options:0 range:NSMakeRange(0, template.length)];
	[template replaceOccurrencesOfString:@"{text}" withString:self.message.text ? self.message.text : NSLocalizedString(@"Can't load the message body.", nil) options:0 range:NSMakeRange(0, template.length)];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
	NSString* dateString = [dateFormatter stringFromDate:self.message.header.sentDate];
	[template replaceOccurrencesOfString:@"{date}" withString:dateString ? dateString : @"" options:0 range:NSMakeRange(0, template.length)];
	[self.webView loadHTMLString:template baseURL:nil];
	
    // Do any additional setup after loading the view from its nib.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark UIWebViewDelegate

- (void) webViewDidFinishLoad:(UIWebView *)aWebView {
	float delayInSeconds = 0.1;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		self.webView.hidden = NO;
	});
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSURL* url = request.URL;
	if ([url.scheme hasPrefix:@"http"]) {
		[[UIApplication sharedApplication] openURL:url];
		return NO;
	}
	else
		return YES;
}

@end
