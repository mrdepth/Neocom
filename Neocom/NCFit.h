//
//  NCFit.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCFit : NSManagedObject

@property (nonatomic, retain) NSString * fitName;
@property (nonatomic, retain) NSString * imageName;
@property (nonatomic) int32_t typeID;
@property (nonatomic, retain) NSString * typeName;
@property (nonatomic, retain) NSString * url;

@end
