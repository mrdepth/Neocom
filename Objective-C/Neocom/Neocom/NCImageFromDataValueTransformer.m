//
//  NCImageFromDataValueTransformer.m
//  Neocom
//
//  Created by Artem Shimanski on 23.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCImageFromDataValueTransformer.h"

@implementation NCImageFromDataValueTransformer

- (id) transformedValue:(id)value {
	return [UIImage imageWithData:value scale:UIScreen.mainScreen.scale];
}

@end
