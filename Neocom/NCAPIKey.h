//
//  NCAPIKey.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCAPIKey : NSManagedObject

@property (nonatomic) int32_t keyID;
@property (nonatomic, retain) NSString * vCode;

@end
