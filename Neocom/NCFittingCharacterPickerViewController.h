//
//  NCFittingCharacterPickerViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCFitCharacter.h"

@interface NCFittingCharacterPickerViewController : UINavigationController

- (void) presentInViewController:(UIViewController*) controller fromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated completionHandler:(void(^)(NCFitCharacter* character)) completion;

@end
