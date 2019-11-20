//
//  NCDBImageValueTransformer.m
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBImageValueTransformer.h"
#import <UIKit/UIKit.h>

@implementation NCDBImageValueTransformer

+ (void) initialize {
	[self setValueTransformer:[NCDBImageValueTransformer new] forName:@"NCDBImageValueTransformer"];
}

- (id) transformedValue:(id)value {
	return UIImagePNGRepresentation(value);
}

- (id) reverseTransformedValue:(id)value {
	return [UIImage imageWithData:value];
}

@end
