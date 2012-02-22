//
//  EUSingleBlockOperation.h
//  EVEUniverse
//
//  Created by Shimanski on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EUSingleBlockOperation : NSBlockOperation {
	NSString *identifier;
}
@property (nonatomic, retain) NSString *identifier;

+ (id) operationWithIdentifier:(NSString*) aIdentifier;
- (id) initWithIdentifier:(NSString*) aIdentifier;

@end
