//
//  NCSlideDownInteractiveTransition.h
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCSlideDownInteractiveTransition : UIPercentDrivenInteractiveTransition

- (instancetype) initWithScrollView:(UIScrollView*) scrollView;
@end
