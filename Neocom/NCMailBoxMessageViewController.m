//
//  NCMailBoxMessageViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 26.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMailBoxMessageViewController.h"
#import "NCMailBox.h"

@interface NCMailBoxMessageViewController ()

@end

@implementation NCMailBoxMessageViewController

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
	self.title = self.message.header.title;
	
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 [self.message body];
											 
										 }
							 completionHandler:^(NCTask *task) {
								 NSMutableArray* to = [NSMutableArray new];
								 for (NCMailBoxContact* recipient in self.message.recipients)
									 if (recipient.name.length > 0)
										 [to addObject:recipient.name];
								 
								 NSMutableString* template = [NSMutableString stringWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"mailMessageTemplate" ofType:@"html"]]
																							 encoding:NSUTF8StringEncoding error:nil];
								 [template replaceOccurrencesOfString:@"{subject}"
														   withString:self.message.header.title ? self.message.header.title : @""
															  options:0
																range:NSMakeRange(0, template.length)];
								 
								 [template replaceOccurrencesOfString:@"{from}"
														   withString:self.message.sender.name.length > 0 ? self.message.sender.name : NSLocalizedString(@"Unknown", nil)
															  options:0
																range:NSMakeRange(0, template.length)];
								 
								 [template replaceOccurrencesOfString:@"{to}"
														   withString:to ? [to componentsJoinedByString:@", "] : @""
															  options:0
																range:NSMakeRange(0, template.length)];
								 
								 [template replaceOccurrencesOfString:@"{text}"
														   withString:self.message.body.text  ? self.message.body.text : NSLocalizedString(@"Can't load the message body.", nil)
															  options:0
																range:NSMakeRange(0, template.length)];
								 
								 NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
								 [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
								 [dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm"];
								 
								 [template replaceOccurrencesOfString:@"{date}"
														   withString:self.message.header.sentDate ? [dateFormatter stringFromDate:self.message.header.sentDate] : @""
															  options:0
																range:NSMakeRange(0, template.length)];
								 
								 [self.webView loadHTMLString:template baseURL:nil];
								 [self.message.mailBox markAsRead:@[self.message]];
							 }];
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
