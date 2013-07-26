//
//  CALayer+UIColor.m
//  EVEUniverse
//
//  Created by mr_depth on 19.07.13.
//
//

#import "CALayer+UIColor.h"
#import <objc/runtime.h>

@implementation CALayer (UIColor)

- (void) setBorderUIColor:(UIColor*)color {
	[self setBorderColor:[color CGColor]];
	
}

@end