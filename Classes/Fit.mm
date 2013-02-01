//
//  Fit.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 28.01.13.
//
//

#import "Fit.h"

@interface Fit()
@property (nonatomic, readwrite, retain) EVEDBInvType* type;
@end

@implementation Fit
@synthesize type = _type;

@dynamic fitName;
@dynamic imageName;
@dynamic typeID;
@dynamic typeName;
@dynamic url;

- (id) retain {
	return [super retain];
}

- (oneway  void) release {
	[super release];
}

- (void) dealloc {
	[_type release];
	[super dealloc];
}

- (EVEDBInvType*) type {
	if (!_type) {
		if (self.typeID) {
			self.type = [EVEDBInvType invTypeWithTypeID:self.typeID error:nil];
		}
		else
			return nil;
	}
	return _type;
}


- (void) save {
	
}

- (void) load {
	
}

- (void) unload {
	
}


@end
