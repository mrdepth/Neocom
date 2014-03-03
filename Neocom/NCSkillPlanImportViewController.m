//
//  NCSkillPlanImportViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 03.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillPlanImportViewController.h"
#import "ASHTTPServer.h"
#import "UIDevice+IP.h"

@interface NCSkillPlanImportViewController ()<ASHTTPServerDelegate>
@property (nonatomic, strong) ASHTTPServer* server;
@property (nonatomic, strong) NSString* address;
@end

@implementation NCSkillPlanImportViewController

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
	NSArray* files = [[NSFileManager defaultManager] subpathsAtPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]];
	
	NSMutableArray* rows = [[NSMutableArray alloc] init];
	for (NSString* file in files)
		if ([[file pathExtension] compare:@"xml" options:NSCaseInsensitiveSearch] == NSOrderedSame && ![file isEqualToString:@"exportedFits.xml"])
			[rows addObject:file];
	
	self.server = [[ASHTTPServer alloc] initWithName:NSLocalizedString(@"Neocom", nil) port:8080];
	self.server.delegate = self;
	NSError* error = nil;
	if ([self.server startWithError:&error]) {
		NSString* address = [UIDevice localIPAddress];
		if (address) {
			self.address = [NSString stringWithFormat:@"http://%@:8080", address];
			return;
		}
	}
	self.address = NSLocalizedString(@"Check your Wi-Fi settings", nil);
	self.server = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
