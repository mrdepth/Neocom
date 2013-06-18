//
//  TutorialViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TutorialViewController : UIViewController<UIScrollViewDelegate>
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;

- (IBAction) onPageChanged:(id) sender;
@end
