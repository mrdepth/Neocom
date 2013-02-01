//
//  EUStorage.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import <Foundation/Foundation.h>

@interface EUStorage : NSObject
@property (readonly, retain, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, retain, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, retain, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (id) sharedStorage;
+ (void) cleanup;
- (void)saveContext;

@end
