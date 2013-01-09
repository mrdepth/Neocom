//
//  PCViewController.m
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PCViewController.h"
#import "EVEOnlineAPI.h"
#import "UIDevice+IP.h"
#import "Globals.h"

@interface PCViewController(Private)

- (void) updateAddress;

@end


@implementation PCViewController
@synthesize addressLabel;

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
	self.title = NSLocalizedString(@"Add API Key", nil);
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"PCViewController+viewDidLoad" name:NSLocalizedString(@"Loading Accounts", nil)];
	[operation addExecutionBlock:^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[[EVEAccountStorage sharedAccountStorage] reload];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		server = [[EUHTTPServer alloc] initWithDelegate:self];
		[server run];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
	
	[self updateAddress];
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
	[server shutdown];
	[server release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAddress) object:nil];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateAddress) object:nil];
	[addressLabel release];

	[server shutdown];
	[server release];
    [super dealloc];
}

#pragma mark EUHTTPServerDelegate

- (void) server:(EUHTTPServer*) server didReceiveRequest:(EUHTTPRequest*) request connection:(EUHTTPConnection*) connection {
	BOOL canRun = YES;
	
	NSMutableString *page = [NSMutableString stringWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]] encoding:NSUTF8StringEncoding error:nil];
	NSDictionary* arguments = request.arguments;
	
	if (arguments.count > 0) {
		if ([[arguments valueForKey:@"keyID"] length] == 0)
			[page replaceOccurrencesOfString:@"{error}" withString:@"Error: Enter <b>KeyID</b>" options:0 range:NSMakeRange(0, page.length)];
		else if ([[arguments valueForKey:@"vCode"] length] == 0)
			[page replaceOccurrencesOfString:@"{error}" withString:@"Error: Enter <b>Verification Code</b>" options:0 range:NSMakeRange(0, page.length)];
		else {
			canRun = NO;
		}
		
		if (canRun) {
			[page replaceOccurrencesOfString:@"{keyID}" withString:[arguments valueForKey:@"keyID"] options:0 range:NSMakeRange(0, page.length)];
			[page replaceOccurrencesOfString:@"{vCode}" withString:[arguments valueForKey:@"vCode"] options:0 range:NSMakeRange(0, page.length)];
		}
	}
	else {
		[page replaceOccurrencesOfString:@"{error}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
		[page replaceOccurrencesOfString:@"{keyID}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
		[page replaceOccurrencesOfString:@"{vCode}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
	}
	CFHTTPMessageRef message = CFHTTPMessageCreateResponse(NULL, 200, NULL, kCFHTTPVersion1_0);
	connection.response.message = message;
	CFRelease(message);
	
	if (canRun) {
		NSData* bodyData = [page dataUsingEncoding:NSUTF8StringEncoding];
		CFHTTPMessageSetBody(connection.response.message, (CFDataRef) bodyData);
		CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef) @"Content-Length", (CFStringRef) [NSString stringWithFormat:@"%d", bodyData.length]);
		CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef) @"Content-Type", (CFStringRef) @"text/html; charset=UTF-8");

		[connection.response run];
	}
	else {
		__block EUOperation *operation = [EUOperation operationWithIdentifier:@"PCViewController+Request" name:NSLocalizedString(@"Checking API Key", nil)];
		[operation addExecutionBlock:^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSError *error = nil;
			NSInteger keyID = [[arguments valueForKey:@"keyID"] integerValue];
			NSString* vCode = [arguments valueForKey:@"vCode"];
			
			[[EVEAccountStorage sharedAccountStorage] addAPIKeyWithKeyID:keyID vCode:vCode error:&error];
			if (error) {
				[page replaceOccurrencesOfString:@"{error}" withString:[NSString stringWithFormat:@"Error: %@", [error localizedDescription]] options:0 range:NSMakeRange(0, page.length)];
				[page replaceOccurrencesOfString:@"{keyID}" withString:[arguments valueForKey:@"keyID"] options:0 range:NSMakeRange(0, page.length)];
				[page replaceOccurrencesOfString:@"{vCode}" withString:[arguments valueForKey:@"vCode"] options:0 range:NSMakeRange(0, page.length)];
			}
			else {
				[page replaceOccurrencesOfString:@"{error}" withString:NSLocalizedString(@"Key added", nil) options:0 range:NSMakeRange(0, page.length)];
				[page replaceOccurrencesOfString:@"{keyID}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
				[page replaceOccurrencesOfString:@"{vCode}" withString:@"" options:0 range:NSMakeRange(0, page.length)];
			}
			[pool release];
		}];
		
		[operation setCompletionBlockInCurrentThread:^(void) {
			NSData* bodyData = [page dataUsingEncoding:NSUTF8StringEncoding];
			CFHTTPMessageSetBody(connection.response.message, (CFDataRef) bodyData);
			CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef) @"Content-Length", (CFStringRef) [NSString stringWithFormat:@"%d", bodyData.length]);
			CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef) @"Content-Type", (CFStringRef) @"text/html; charset=UTF-8");

			[connection.response run];
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
}

@end

@implementation PCViewController(Private)

- (void) updateAddress {
	NSArray *addresses = [UIDevice localIPAddresses];
	if (addresses.count == 0) {
		[self performSelector:@selector(updateAddress) withObject:nil afterDelay:1];
		self.addressLabel.text = NSLocalizedString(@"Unknown IP Address", nil);
	}
	else {
		NSMutableString *text = [NSMutableString string];
		for (NSString *ip in addresses)
			[text appendFormat:@"http://%@:8080\n", ip];
		self.addressLabel.text = text;
		CGRect r = CGRectMake(self.addressLabel.frame.origin.x, self.addressLabel.frame.origin.y, self.addressLabel.frame.size.width, 100);
		r = [self.addressLabel textRectForBounds:r limitedToNumberOfLines:0];
		r.origin = self.addressLabel.frame.origin;
		r.size.width = self.addressLabel.frame.size.width;
		r.size.height += 20;
		self.addressLabel.frame = r;
	}
}

@end

/*
Connect your device via Wi-Fi to LAN

*/