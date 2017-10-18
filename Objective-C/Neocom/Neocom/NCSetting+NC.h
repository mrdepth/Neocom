//
//  NCSetting+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCSetting+CoreDataClass.h"

@interface NCSetting (NC)

+ (instancetype) settingForKey:(NSString*) key;

@end
