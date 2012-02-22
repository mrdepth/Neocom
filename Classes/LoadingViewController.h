//
//  LoadingViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LoadingViewController : UIViewController {
	UIActivityIndicatorView *activityIndicatorView;
}
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@end
