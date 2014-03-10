//
//  Fit.h
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "eufe.h"

@interface Fit : NSManagedObject
@property (nonatomic, strong) NSString * fitName;
@property (nonatomic, strong) NSString * imageName;
@property (nonatomic) eufe::TypeID typeID;
@property (nonatomic, strong) NSString * typeName;
@property (nonatomic, strong) NSString * url;

@end
