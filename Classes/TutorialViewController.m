//
//  TutorialViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TutorialViewController.h"


@implementation TutorialViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Tutorial", nil);
	NSArray *images = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tutorial" ofType:@"plist"]]];
	int x = 20;
	for (NSString *imageName in images) {
		UIImageView *imageView = [[UIImageView alloc]  initWithImage:[UIImage imageNamed:imageName]];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			imageView.contentMode = UIViewContentModeCenter;
		else
			imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.frame = CGRectMake(x, 0, self.scrollView.frame.size.width - 40, self.scrollView.frame.size.height);
		[self.scrollView addSubview:imageView];
		x += self.scrollView.frame.size.width;
	}
	self.scrollView.contentSize = CGSizeMake(x - 20, self.scrollView.frame.size.height);
	self.pageControl.numberOfPages = images.count;
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
	self.pageControl = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (IBAction) onPageChanged:(id) sender {
	float x = self.pageControl.currentPage * self.scrollView.frame.size.width;
	[self.scrollView scrollRectToVisible:CGRectMake(x, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height) animated:YES];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView {
	self.pageControl.currentPage = (int) self.scrollView.contentOffset.x / self.scrollView.frame.size.width;
}

@end
