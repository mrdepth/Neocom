//
//  NCCache.m
//  Neocom
//
//  Created by Artem Shimanski on 19.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCache.h"

@interface NCCache(){
	NSManagedObjectContext* _viewContext;
	NSManagedObjectModel* _managedObjectModel;
	NSPersistentStoreCoordinator* _persistentStoreCoordinator;
}

@end

static NCCache* sharedCache;

@implementation NCCache

+ (instancetype) sharedCache {
	return sharedCache;
}

+ (void) setSharedCache:(NCCache*) cache {
	sharedCache = cache;
}

- (id) init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadWithCompletionHandler:(void (^)(NSError* error))block {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NCCache" withExtension:@"momd"];
		_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

		NSString* cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"com.shimanski.eveuniverse.NCCache"];
		[[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
		NSString* storePath = [cacheDirectory stringByAppendingPathComponent:@"store.sqlite"];
		
		NSError *error;
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		for (int i = 0; i < 2; i++) {
			error = nil;
			if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														  configuration:nil
																	URL:[NSURL fileURLWithPath:storePath]
																options:nil
																  error:&error]) {
				break;
			}
			else
				[[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.persistentStoreCoordinator) {
				_viewContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
				_viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
				_viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
				block(nil);
			}
			else if (block)
				block(error ?: [NSError errorWithDomain:@"NCCache" code:-1 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unable to create cache store", nil)}]);
		});
	});
}

- (void)performBackgroundTask:(void (^)(NSManagedObjectContext* managedObjectContext))block {
	NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	context.persistentStoreCoordinator = self.persistentStoreCoordinator;
	context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	[context performBlock:^{
		block(context);
		if ([context hasChanges])
			[context save:nil];
	}];
}

- (void)storeObject:(id<NSSecureCoding>) object forKey:(NSString*) key account:(NSString*) account date:(NSDate*) date expireDate:(NSDate*) expireDate  completionHandler:(void(^)(NSManagedObjectID* objectID)) block {
	[self performBackgroundTask:^(NSManagedObjectContext *managedObjectContext) {
		NCCacheRecord* record = [[managedObjectContext executeFetchRequest:[NCCacheRecord fetchRequestForKey:key account:account] error:nil] lastObject];
		if (!record) {
			record = [NSEntityDescription insertNewObjectForEntityForName:@"Record" inManagedObjectContext:managedObjectContext];
			record.account = account;
			record.key = key;
			record.data = [NSEntityDescription insertNewObjectForEntityForName:@"RecordData" inManagedObjectContext:managedObjectContext];
		}
		record.data.data = (NSObject*) object;
		record.date = date ?: [NSDate date];
		record.expireDate = expireDate ?: record.expireDate ?: [record.date dateByAddingTimeInterval:1];
		if (block)
			dispatch_async(dispatch_get_main_queue(), ^{
				block(record.objectID);
			});
	}];
}


#pragma mark - Private

- (void) managedObjectContextDidSave:(NSNotification*) note {
	NSManagedObjectContext* context = note.object;
	if (context != _viewContext && context.persistentStoreCoordinator == _persistentStoreCoordinator) {
		[_viewContext performBlock:^{
			[_viewContext mergeChangesFromContextDidSaveNotification:note];
		}];
	}
}

@end
