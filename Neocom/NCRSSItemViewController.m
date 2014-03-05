//
//  NCRSSItemViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 05.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCRSSItemViewController.h"
#import "RSS.h"
#import "RSSItem+Neocom.h"

@interface NCRSSItemViewController ()

@end

@implementation NCRSSItemViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = self.rss.plainTitle;
	NSMutableString *htmlString = [NSMutableString stringWithFormat:@"<a href=\"%@\">%@</a><br>%@<br>", [self.rss.link absoluteString], self.rss.title, self.rss.description];
	if (self.rss.enclosure && self.rss.enclosure.url) {
		//NSString *url = [rss.enclosure valueForKey:@"url"];
		[htmlString appendFormat:@"<br><a href=\"%@\"><img width=16 height=16 src=\"%@\"/>Play %@ (%.1f Mb)</a><br>",
		 @"dummy://play",
		 [[[NSBundle mainBundle] URLForResource:(([UIScreen mainScreen].scale == 2.0) ? @"buttonPlay@2x" : @"buttonPlay") withExtension:@"png"] absoluteString],
		 [[self.rss.enclosure.url absoluteString] lastPathComponent],
		 self.rss.enclosure.length / (1024.0 * 1024.0)];
	}
	[self.webView loadHTMLString:htmlString baseURL:self.rss.link];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:request.URL];
		return NO;
	}
	else
		return YES;
}

@end
