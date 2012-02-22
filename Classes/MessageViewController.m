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
#import "NSInvocation+Variadic.h"

@implementation MessageViewController
@synthesize webView;
@synthesize message;

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
	self.title = message.header.title;
	NSMutableString* template = [NSMutableString stringWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"mailMessageTemplate" ofType:@"html"]]
																encoding:NSUTF8StringEncoding error:nil];
	NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		[template replaceOccurrencesOfString:@"{subject}" withString:message.header.title options:0 range:NSMakeRange(0, template.length)];
		[template replaceOccurrencesOfString:@"{from}" withString:message.from options:0 range:NSMakeRange(0, template.length)];
		[template replaceOccurrencesOfString:@"{to}" withString:message.to options:0 range:NSMakeRange(0, template.length)];
		[template replaceOccurrencesOfString:@"{text}" withString:message.text options:0 range:NSMakeRange(0, template.length)];
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
		[template replaceOccurrencesOfString:@"{date}" withString:[dateFormatter stringFromDate:message.header.sentDate] options:0 range:NSMakeRange(0, template.length)];
		[dateFormatter release];

		[pool release];
	}];
	[operation setCompletionBlockInCurrentThread:^{
		[webView loadHTMLString:template baseURL:nil];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [webView release];
	[message release];
    [super dealloc];
}

#pragma mark UIWebViewDelegate

- (void) webViewDidFinishLoad:(UIWebView *)aWebView {
	BOOL no = NO;
	NSInvocation* invocation = [NSInvocation invocationWithTarget:webView selector:@selector(setHidden:) argumentPointers:&no];
	[invocation performSelector:@selector(invoke) withObject:0 afterDelay:0.1];
	//webView.hidden = NO;
}

@end
