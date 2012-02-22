//
//  Character.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "eufe.h"

@interface Character : NSObject<NSCoding> {
	NSInteger characterID;
	NSString* name;
	NSMutableDictionary* skills;
}
@property (nonatomic, assign) NSInteger characterID;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, readonly, retain) NSMutableDictionary* skills;

+ (NSString*) charactersDirectory;
- (NSString*) guid;
- (id) initWithCoder:(NSCoder *)aDecoder;
- (void) encodeWithCoder:(NSCoder *)aCoder;
- (void) save;
- (boost::shared_ptr<std::map<eufe::TypeID, int> >) skillsMap;

@end
