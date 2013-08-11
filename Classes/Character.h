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
