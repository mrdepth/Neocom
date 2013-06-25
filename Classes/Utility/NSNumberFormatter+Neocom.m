//
//  NSNumberFormatter+Neocom.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 20.06.13.
//
//

#import "NSNumberFormatter+Neocom.h"

static NSNumberFormatter* sharedIntegerNumberFormatter;

@implementation NSNumberFormatter (Neocom)

+ (NSString *)neocomLocalizedStringFromInteger:(NSInteger)value {
	@synchronized(self) {
		if (!sharedIntegerNumberFormatter) {
			sharedIntegerNumberFormatter = [[NSNumberFormatter alloc] init];
			[sharedIntegerNumberFormatter setPositiveFormat:@"#,##0"];
			[sharedIntegerNumberFormatter setGroupingSeparator:@" "];
		}
		return [sharedIntegerNumberFormatter stringFromNumber:@(value)];
	}
}

@end
