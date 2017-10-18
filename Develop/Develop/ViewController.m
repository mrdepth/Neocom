//
//  ViewController.m
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "ViewController.h"
@import CoreData;

@interface NCMyStore : NSIncrementalStore

@end

@implementation NCMyStore

- (nullable id)executeRequest:(NSPersistentStoreRequest *)request withContext:(nullable NSManagedObjectContext*)context error:(NSError **)error {
	return nil;
}

- (nullable NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID*)objectID withContext:(NSManagedObjectContext*)context error:(NSError**)error {
	return nil;
}

-(BOOL)loadMetadata:(NSError **)error {
	return YES;
}

@end



@interface ViewController ()
@property (nonatomic, strong) NSPersistentStoreCoordinator* coordinator;
@end

@implementation ViewController

- (void)viewDidLoad {
	[NSPersistentStoreCoordinator registerStoreClass:[NCMyStore class] forStoreType:@"NCMyStore"];
	NSManagedObjectModel* model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"NCCache" withExtension:@"momd"]];
	self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	NSURL* url = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"test.sqlite"]];
	[self.coordinator addPersistentStoreWithType:@"NCMyStore" configuration:nil URL:url options:nil error:nil];
	NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	context.persistentStoreCoordinator = self.coordinator;
	
	[NSEntityDescription insertNewObjectForEntityForName:@"Record" inManagedObjectContext:context];
	[context save:nil];
	//NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Record"];
	//[context executeFetchRequest:request error:nil];
	
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


@end
