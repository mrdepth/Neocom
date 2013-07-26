//
//  AboutViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AboutViewController.h"
#import "Globals.h"
#import "EVEUniverseAppDelegate.h"
#import "EVEAccount.h"

@interface AboutViewController()

- (NSUInteger) contentsSizeOfDirectoryAtPath:(NSString*) path;
- (void) reload;

@end


@implementation AboutViewController

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
	self.title = NSLocalizedString(@"About", nil);
	self.databaseVersionLabel.text = @"Retribution_1.1_84566";
	self.imagesVersionLabel.text = @"Retribution_1.1_imgs";
	
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	self.applicationVersionLabel.text = [NSString stringWithFormat:@"%@", [info valueForKey:@"CFBundleVersion"]];
	
	[self reload];
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


- (IBAction) onClearCache:(id) sender {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning!", nil) message:NSLocalizedString(@"Some features may be temporarily unavailable.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Clear", nil), nil];
	[alertView show];
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
		[[NSURLCache sharedURLCache] removeAllCachedResponses];
		self.apiCacheSizeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ bytes", nil), @(0)];

//		[self reload];
		//[EVEAccount reload];
		
	}
}

#pragma mark - Private

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
	for (UIView *v in [self.scrollView subviews])
		[v removeFromSuperview];

	float y = 0;
	
	[self.scrollView addSubview:self.cacheView];
	self.cacheView.frame = CGRectMake(0, y, self.cacheView.frame.size.width, self.cacheView.frame.size.height);
	y += self.cacheView.frame.size.height;
	
	[self.scrollView addSubview:self.databaseView];
	self.databaseView.frame = CGRectMake(0, y, self.databaseView.frame.size.width, self.databaseView.frame.size.height);
	y += self.databaseView.frame.size.height;
	
	[self.scrollView addSubview:self.marketView];
	self.marketView.frame = CGRectMake(0, y, self.marketView.frame.size.width, self.marketView.frame.size.height);
	y += self.marketView.frame.size.height;

	[self.scrollView addSubview:self.specialThanksView];
	self.specialThanksView.frame = CGRectMake(0, y, self.specialThanksView.frame.size.width, self.specialThanksView.frame.size.height);
	y += self.specialThanksView.frame.size.height;

	[self.scrollView addSubview:self.versionView];
	self.versionView.frame = CGRectMake(0, y, self.versionView.frame.size.width, self.versionView.frame.size.height);
	y += self.versionView.frame.size.height;
	
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
		y += 50;

	self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, y);
	NSURLCache* cache = [NSURLCache sharedURLCache];
	self.apiCacheSizeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ bytes", nil), [NSNumberFormatter localizedStringFromNumber:@([cache currentDiskUsage] + [cache currentMemoryUsage]) numberStyle:NSNumberFormatterDecimalStyle]];
}

@end
