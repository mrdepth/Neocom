//
//  NCFetchedCollection.h
//  Develop
//
//  Created by Artem Shimanski on 23.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCFetchedCollection.h"

@class NSManagedObjectContext;
@interface NCFetchedCollection<__covariant ObjectType> : NSObject
@property (nonatomic, copy) NSString* entityName;
@property (nonatomic, copy) NSString* predicateFormat;
@property (nonatomic, strong) NSArray* argumentArray;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;

- (id) initWithEntity:(NSString*) entityName predicateFormat:(NSString*) predicateFormat argumentArray:(NSArray*) argumentArray managedObjectContext:(NSManagedObjectContext*) managedObjectContext;

- (ObjectType) objectAtIndexedSubscript:(NSInteger) index;

@end
