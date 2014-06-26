//
//  NCDBImageValueTransformer.m
//  NCDatabase
//
//  Created by Артем Шиманский on 12.05.14.
//
//

#import "NCDBImageValueTransformer.h"

@implementation NCDBImageValueTransformer

+ (void) initialize {
	[self setValueTransformer:[NCDBImageValueTransformer new] forName:@"NCDBImageValueTransformer"];
}

- (id) transformedValue:(id)value {
	return [value representationUsingType:NSPNGFileType properties:nil];
}

- (id) reverseTransformedValue:(id)value {
	return [[NSBitmapImageRep alloc] initWithData:value];
}

@end
