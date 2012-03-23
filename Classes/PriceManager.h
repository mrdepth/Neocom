//
//  PriceManager.h
//  EVEUniverse
//
//  Created by Mr. Depth on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EVEDBInvType;
@interface PriceManager : NSObject {
@private
	NSMutableDictionary* prices;
}

- (float) priceWithType:(EVEDBInvType*) type;
- (NSDictionary*) pricesWithTypes:(NSArray*) types;

@end
