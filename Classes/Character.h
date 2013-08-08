//
//  Character.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "eufe.h"

@protocol Character
@property (nonatomic, copy) NSString* name;
@property (nonatomic, strong) NSMutableDictionary* skillsDictionary;
@property (nonatomic, readonly, getter = isReadonly) BOOL readonly;

- (boost::shared_ptr<std::map<eufe::TypeID, int> >) skillsMap;
@end

@interface Character : NSObject<NSCoding>
@property (nonatomic, assign) NSInteger characterID;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, strong) NSMutableDictionary* skills;

+ (NSString*) charactersDirectory;
- (NSString*) guid;
- (id) initWithCoder:(NSCoder *)aDecoder;
- (void) encodeWithCoder:(NSCoder *)aCoder;
- (void) save;
- (boost::shared_ptr<std::map<eufe::TypeID, int> >) skillsMap;

@end
