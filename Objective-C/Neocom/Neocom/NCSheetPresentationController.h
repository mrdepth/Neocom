//
//  NCSheetPresentationController.h
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCSheetSegue : UIStoryboardSegue

@end

@interface NCSheetPresentationController : UIPresentationController<UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@end
