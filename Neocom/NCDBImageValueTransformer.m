//
//  NCDBImageValueTransformer.m
//  Neocom
//
//  Created by Артем Шиманский on 10.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBImageValueTransformer.h"

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
