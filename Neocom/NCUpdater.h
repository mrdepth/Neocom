//
//  NCUpdater.h
//  Neocom
//
//  Created by Artem Shimanski on 18.10.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NCDatabaseDidInstallUpdateNotification @"NCDatabaseDidInstallUpdateNotification"

@interface NCUpdater : NSObject
@property (nonatomic, strong, readonly) NSProgress* progress;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, retain) NSString* libraryDirectory;
@property (nonatomic, retain) NSString* versionDirectory;

+ (instancetype) sharedUpdater;

- (void) checkForUpdates;
- (NSInteger) applicationVersion;

@end
