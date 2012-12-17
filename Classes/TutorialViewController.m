//
//  TutorialViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TutorialViewController.h"


@implementation TutorialViewController
@synthesize scrollView;
@synthesize pageControl;

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
	self.title = NSLocalizedString(@"Tutorial", nil);
	NSArray *images = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tutorial" ofType:@"plist"]]];
	int x = 20;
	for (NSString *imageName in images) {
		UIImageView *imageView = [[[UIImageView alloc]  initWithImage:[UIImage imageNamed:imageName]] autorelease];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			imageView.contentMode = UIViewContentModeCenter;
		else
			imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.frame = CGRectMake(x, 0, scrollView.frame.size.width - 40, scrollView.frame.size.height);
		[scrollView addSubview:imageView];
		x += scrollView.frame.size.width;
	}
	scrollView.contentSize = CGSizeMake(x - 20, scrollView.frame.size.height);
	pageControl.numberOfPages = images.count;
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
	self.pageControl = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[scrollView release];
	[pageControl release];
    [super dealloc];
}

- (IBAction) onPageChanged:(id) sender {
	float x = pageControl.currentPage * scrollView.frame.size.width;
	[scrollView scrollRectToVisible:CGRectMake(x, 0, scrollView.frame.size.width, scrollView.frame.size.height) animated:YES];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView {
	pageControl.currentPage = (int) scrollView.contentOffset.x / 320;
}

@end
