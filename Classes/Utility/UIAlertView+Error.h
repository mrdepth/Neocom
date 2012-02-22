//
//  UIAlertView+Error.h
//  
//
//  Created by Artem Shimanski on 9/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIAlertView(Error)
+ (UIAlertView*) alertViewWithError: (NSError*) error;

@end
