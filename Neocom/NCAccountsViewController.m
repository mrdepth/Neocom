//
//  NCAccountsViewController.m
//  Neocom
//
//  Created by Admin on 04.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAccountsViewController.h"
#import "NCAccountsManager.h"
#import "NCStorage.h"

@interface NCAccountsViewControllerDataAccount : NSObject<NSCoding>
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) EVEAccountStatus* accountStatus;
@end

@implementation NCAccountsViewControllerDataAccount

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		NCStorage* storage = [NCStorage sharedStorage];
		
		NSURL* url = [aDecoder decodeObjectForKey:@"account"];
		if ([url isKindOfClass:[NSURL class]]) {
			[storage.managedObjectContext performBlockAndWait:^{
				self.account = (NCAccount*) [storage.managedObjectContext objectWithID:[storage.persistentStoreCoordinator managedObjectIDForURIRepresentation:url]];
			}];
			self.accountStatus = [aDecoder decodeObjectForKey:@"accountStatus"];
			if (![self.accountStatus isKindOfClass:[EVEAccountStatus class]])
				self.accountStatus = nil;
		}
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.account)
		[aCoder encodeObject:[self.account.objectID URIRepresentation] forKey:@"account"];
	if (self.accountStatus)
		[aCoder encodeObject:self.accountStatus forKey:@"accountStatus"];
}

@end

@interface NCAccountsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSMutableArray* accounts;
@property (nonatomic, strong) NSMutableArray* apiKeys;
@end



@implementation NCAccountsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		NCStorage* storage = [NCStorage sharedStorage];
        
		NSArray* accounts = [aDecoder decodeObjectForKey:@"accounts"];
        self.accounts = [NSMutableArray arrayWithArray:accounts];
        [storage.managedObjectContext performBlockAndWait:^{
            self.apiKeys = [NSMutableArray arrayWithArray:[NCAPIKey allAPIKeys]];
        }];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    if (self.accounts)
        [aCoder encodeObject:self.accounts forKey:@"accounts"];
}

@end


@interface NCAccountsViewController ()

@end

@implementation NCAccountsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NCTableViewController

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccountsViewControllerData* data = [NCAccountsViewControllerData new];
    data.accounts = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCAccountsManager* accountsManager = [NCAccountsManager defaultManager];
											 
											 float p = 0;
											 float dp = 1.0 / (accountsManager.accounts.count + accountsManager.apiKeys.count);
											 NSMutableDictionary* accountStatuses = [NSMutableDictionary new];
											 
											 for (NCAPIKey* apiKey in accountsManager.apiKeys) {
												 NSError* error = nil;
												 EVEAccountStatus* accountStatus = [EVEAccountStatus accountStatusWithKeyID:apiKey.keyID vCode:apiKey.vCode cachePolicy:cachePolicy error:&error progressHandler:nil];
												 accountStatuses[@([apiKey hash])] = accountStatus ? accountStatus : error;
												 task.progress = p += dp;
											 }
											 
											 for (NCAccount* account in accountsManager.accounts) {
												 [account reloadWithCachePolicy:cachePolicy error:&error];
                                                 NCAccountsViewControllerDataAccount* dataAccount = [NCAccountsViewControllerDataAccount new];
                                                 dataAccount.account = account;
                                                 dataAccount.accountStatus = accountStatuses[@([account.apiKey hash])];
                                                 [data.accounts addObject:dataAccount];
												 task.progress = p += dp;
											 }
                                             NCStorage* storage = [NCStorage sharedStorage];
                                             [storage.managedObjectContext performBlockAndWait:^{
                                                 data.apiKeys = [[NSMutableArray alloc] initWithArray:[NCAPIKey allAPIKeys]];
                                             }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
                                         [self didFinishLoadData:data withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
									 }
								 }
							 }];
}

@end
