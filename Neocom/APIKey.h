//
//  APIKey.h
//  Neocom
//
//  Created by Артем Шиманский on 10.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface APIKey : NSManagedObject
@property (nonatomic) int32_t keyID;
@property (nonatomic, strong) NSString * vCode;

@end
