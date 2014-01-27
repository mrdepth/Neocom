//
//  NCCalendarEventDetailsViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 23.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCCalendarEventDetailsViewController.h"
#import "EVEOnlineAPI.h"

@interface NCCalendarEventDetailsViewController ()

@end

@implementation NCCalendarEventDetailsViewController

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
	NSMutableString* text = [[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"eventTemplate" ofType:@"html"]
																	 encoding:NSUTF8StringEncoding
																		error:nil];
	[text replaceOccurrencesOfString:@"{subject}"
						  withString:self.event.eventTitle
							 options:0
							   range:NSMakeRange(0, text.length)];
	
	[text replaceOccurrencesOfString:@"{from}"
						  withString:self.event.ownerID == 1 ? @"CCP" : self.event.ownerName
							 options:0
							   range:NSMakeRange(0, text.length)];
	
	[text replaceOccurrencesOfString:@"{duration}"
						  withString:[NSString stringWithFormat:NSLocalizedString(@"%.1f hours", nil), self.event.duration / 60.0]
							 options:0
							   range:NSMakeRange(0, text.length)];
	
	NSDateFormatter* dateFormatter = nil;
	dateFormatter = [NSDateFormatter new];
	[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
	
	[text replaceOccurrencesOfString:@"{date}"
						  withString:[dateFormatter stringFromDate:self.event.eventDate]
							 options:0
							   range:NSMakeRange(0, text.length)];
	

	[text replaceOccurrencesOfString:@"{response}"
						  withString:self.event.response
							 options:0
							   range:NSMakeRange(0, text.length)];

	[text replaceOccurrencesOfString:@"{text}"
						  withString:self.event.eventText
							 options:0
							   range:NSMakeRange(0, text.length)];

	[self.webView loadHTMLString:text baseURL:nil];
	
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
