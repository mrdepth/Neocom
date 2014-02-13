//
//  NCAssetsViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAssetsViewController.h"

@interface NCAssetsViewControllerDataLocation : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* assets;
@property (nonatomic, strong) NSString* title;

@end

@interface NCAssetsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* locations;
@property (nonatomic, strong) NSDictionary* types;
@end


@interface NCAssetsViewController ()

@end

@implementation NCAssetsViewController

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
	NCAccount* account = [NCAccount currentAccount];
	if (!account || account.accountType == NCAccountTypeCorporate) {
		[self didFinishLoadData:nil withCacheDate:nil expireDate:nil];
		return;
	}
	NSMutableArray* rows = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
									 if (error) {
										 [self didFailLoadDataWithError:error];
									 }
									 else {
										 [self didFinishLoadData:rows withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
									 }
								 }
							 }];
}

- (void) didChangeAccount:(NCAccount *)account {
	[super didChangeAccount:account];
	if ([self isViewLoaded])
		[self reloadDataWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
}


@end
