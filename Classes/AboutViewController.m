//
//  AboutViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AboutViewController.h"
#import "EVERequestsCache.h"
#import "Globals.h"
#import "EVEUniverseAppDelegate.h"
#import "EVEAccount.h"

@interface AboutViewController(Private)

- (NSUInteger) contentsSizeOfDirectoryAtPath:(NSString*) path;
- (void) reload;

@end


@implementation AboutViewController
@synthesize scrollView;
@synthesize cacheView;
@synthesize databaseView;
@synthesize marketView;
@synthesize versionView;
@synthesize specialThanksView;
@synthesize apiCacheSizeLabel;
@synthesize imagesCacheSizeLabel;
@synthesize databaseVersionLabel;
@synthesize imagesVersionLabel;
@synthesize applicationVersionLabel;



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
	self.title = @"About";
	databaseVersionLabel.text = @"Inferno_1.1_73052";
	imagesVersionLabel.text = @"Inferno_1.1_imgs";
	
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	applicationVersionLabel.text = [NSString stringWithFormat:@"%@", [info valueForKey:@"CFBundleVersion"]];
	
	[self reload];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.scrollView = nil;
	self.cacheView = nil;
	self.databaseView = nil;
	self.marketView = nil;
	self.versionView = nil;
	self.specialThanksView = nil;
	self.apiCacheSizeLabel = nil;
	self.imagesCacheSizeLabel = nil;
	self.databaseVersionLabel = nil;
	self.imagesVersionLabel = nil;
	self.applicationVersionLabel = nil;
}


- (void)dealloc {
	[scrollView release];
	[cacheView release];
	[databaseView release];
	[marketView release];
	[versionView release];
	[specialThanksView release];
	[apiCacheSizeLabel release];
	[imagesCacheSizeLabel release];
	[databaseVersionLabel release];
	[imagesVersionLabel release];
	[applicationVersionLabel release];
	
    [super dealloc];
}

- (IBAction) onClearCache:(id) sender {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning!" message:@"Some features may be temporarily unavailable." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
	[alertView show];
	[alertView release];
}

- (IBAction) onHomepage:(id) sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.eveuniverseiphone.com"]];
}

- (IBAction) onMail:(id) sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:support@eveuniverseiphone.com"]];
}

- (IBAction) onSources:(id) sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/mrdepth"]];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[[EVERequestsCache sharedRequestsCache] clear];
		[[NSURLCache sharedURLCache] removeAllCachedResponses];
		[self reload];
		[EVEAccount reload];
	}
}

@end

@implementation AboutViewController(Private)

- (NSUInteger) contentsSizeOfDirectoryAtPath:(NSString*) path {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *items = [fileManager contentsOfDirectoryAtPath:path error:nil];
	NSUInteger size = 0;
	for (NSString *item in items) {
		size += [[fileManager attributesOfItemAtPath:[path stringByAppendingPathComponent:item] error:nil] fileSize];
	}
	return size;
}

- (void) reload {
	for (UIView *v in [scrollView subviews])
		[v removeFromSuperview];

	float y = 0;
	
	[scrollView addSubview:cacheView];
	cacheView.frame = CGRectMake(0, y, cacheView.frame.size.width, cacheView.frame.size.height);
	y += cacheView.frame.size.height;
	
	[scrollView addSubview:databaseView];
	databaseView.frame = CGRectMake(0, y, databaseView.frame.size.width, databaseView.frame.size.height);
	y += databaseView.frame.size.height;
	
	[scrollView addSubview:marketView];
	marketView.frame = CGRectMake(0, y, marketView.frame.size.width, marketView.frame.size.height);
	y += marketView.frame.size.height;

	[scrollView addSubview:specialThanksView];
	specialThanksView.frame = CGRectMake(0, y, specialThanksView.frame.size.width, specialThanksView.frame.size.height);
	y += specialThanksView.frame.size.height;

	[scrollView addSubview:versionView];
	versionView.frame = CGRectMake(0, y, versionView.frame.size.width, versionView.frame.size.height);
	y += versionView.frame.size.height;
	
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		y += 50;

	scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, y);
	
	NSString *path = [EVERequestsCache cacheDirectory];
	apiCacheSizeLabel.text = [NSString stringWithFormat:@"%@ bytes", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithUnsignedInteger:[self contentsSizeOfDirectoryAtPath:path]] numberStyle:NSNumberFormatterDecimalStyle]];
}

@end
