//
//  EUFilterItemValue.h
//  EVEUniverse
//
//  Created by Mr. Depth on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EUFilterItemValue : NSObject {
	NSString *title;
	NSObject *value;
	BOOL enabled;
}
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSObject *value;
@property (nonatomic) BOOL enabled;

@end
