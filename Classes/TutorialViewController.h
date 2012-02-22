//
//  TutorialViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TutorialViewController : UIViewController<UIScrollViewDelegate> {
	UIScrollView *scrollView;
	UIPageControl *pageControl;
}
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *pageControl;

- (IBAction) onPageChanged:(id) sender;
@end
