//
//  NCUpdater.m
//  Neocom
//
//  Created by Artem Shimanski on 18.10.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCUpdater.h"
#import <zlib.h>
#import "NCDatabase.h"

@interface NCUpdater()
@property (nonatomic, strong) CKDatabase* database;
@property (nonatomic, strong) CKQueryOperation* queryOperation;
@property (nonatomic, strong) CKFetchRecordsOperation* fetchRecordsOperation;
@property (nonatomic, strong, readwrite) NSProgress* progress;
@property (nonatomic, assign, readwrite) NCUpdaterState state;
@property (nonatomic, strong) CKRecord* record;

- (void) setupDirectory;
- (UIViewController*) presentedViewController;
- (void) downloadUpdateWithRecord:(CKRecord*) record;
- (void) installUpdateWithRecord:(CKRecord*) record;
- (BOOL) decompressFileAtPath:(NSString*) srcPath toPath:(NSString*) dstPath error:(NSError* _Nullable * _Nullable) error;
@end

@implementation NCUpdater

+ (instancetype) sharedUpdater {
	static NCUpdater* sharedUpdater;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedUpdater = [NCUpdater new];
	});
	return sharedUpdater;
}

- (id) init {
	if (self = [super init]) {
		self.progress = [NSProgress progressWithTotalUnitCount:2];
//		[self.progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:nil];
	}
	return self;
}

/*- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
	NSLog(@"%@", change[NSKeyValueChangeNewKey]);
}*/

- (NSInteger) applicationVersion {
	static NSInteger applicationVersion = 0;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		applicationVersion = [[[[NSBundle mainBundle] infoDictionary][(__bridge NSString*)kCFBundleVersionKey] pathExtension] integerValue];
//		applicationVersion = 11856;
	});
	return applicationVersion;
}

- (void) checkForUpdates {
	[self setupDirectory];
	if (!self.database)
		self.database = [[CKContainer defaultContainer] publicCloudDatabase];
	
	int currentBuild = [[[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType] version].build;
	
	if (self.fetchRecordsOperation) {
		return;
	}
	else {
		//Resume download/install
		NSFileManager* fileManager = [NSFileManager defaultManager];

		NSString* downloadRecordPath = [self.versionDirectory stringByAppendingPathComponent:@"download.record"];
		CKRecord* downloadRecord = [NSKeyedUnarchiver unarchiveObjectWithFile:downloadRecordPath];
		if (downloadRecord) {
			int build = [downloadRecord[@"build"] intValue];
			CKAsset* eufe = downloadRecord[@"eufe"];
			CKAsset* database = downloadRecord[@"database"];
			database = eufe;
			
			if (build > currentBuild) {
				self.record = downloadRecord;
				if (eufe && database && [fileManager fileExistsAtPath:eufe.fileURL.path] && [fileManager fileExistsAtPath:database.fileURL.path]) {
					self.progress.completedUnitCount = 1;
					[self installUpdateWithRecord:downloadRecord];
					return;
				}
				else {
					[self downloadUpdateWithRecord:downloadRecord];
					return;
				}
			}
			else {
				[fileManager removeItemAtPath:downloadRecordPath error:nil];
				if (eufe && [fileManager fileExistsAtPath:eufe.fileURL.path])
					[fileManager removeItemAtURL:eufe.fileURL error:nil];
				if (database && [fileManager fileExistsAtPath:database.fileURL.path])
					[fileManager removeItemAtURL:database.fileURL error:nil];
			}
		}
	}
	
	if (!self.queryOperation) {
		//Check updates
		CKQuery* query = [[CKQuery alloc] initWithRecordType:@"Database" predicate:[NSPredicate predicateWithFormat:@"applicationBuild == %d AND build > %d", self.applicationVersion, currentBuild]];
		query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"build" ascending:NO]];
		self.queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
		self.queryOperation.desiredKeys = @[@"build", @"size", @"title"];
		self.queryOperation.resultsLimit = 1;
		self.queryOperation.qualityOfService = NSQualityOfServiceBackground;
		
		[[self queryOperation] setRecordFetchedBlock:^(CKRecord * _Nonnull record) {
			self.record = record;
			NSString* cachedRecordPath = [self.versionDirectory stringByAppendingPathComponent:@"database.record"];
			CKRecord* cachedRecord = [NSKeyedUnarchiver unarchiveObjectWithFile:cachedRecordPath];
			if (cachedRecord && [cachedRecord[@"build"] isEqual:record[@"build"]]) {
				self.state = NCUpdaterStateWaitingForDownload;
			}
			else {
				[NSKeyedArchiver archiveRootObject:record toFile:cachedRecordPath];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					UIAlertController* controller = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ database update available (%.1f MiB)", nil), record[@"title"], [record[@"size"] floatValue] / 1024 / 1024]
																						message:NSLocalizedString(@"Would you like to update?", nil)
																				 preferredStyle:UIAlertControllerStyleAlert];
					[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Download and Update", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
						[self downloadUpdateWithRecord:record];
					}]];
					[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Not now", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
						self.state = NCUpdaterStateWaitingForDownload;
					}]];
					[self.presentedViewController presentViewController:controller animated:YES completion:nil];
				});
			}
		}];
		
		[[self queryOperation] setCompletionBlock:^{
			self.queryOperation = nil;
		}];
		[self.database addOperation:self.queryOperation];
	}
}

- (void) download {
	if (self.record)
		[self downloadUpdateWithRecord:self.record];
}

- (NSString*) updateName {
	return self.record[@"title"];
}

- (NSInteger) updateSize {
	return [self.record[@"size"] integerValue];
}

#pragma mark - Private

- (NSString*) libraryDirectory {
	static NSString* libraryDirectory;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"Database"];
	});
	return libraryDirectory;
}

- (NSString*) versionDirectory {
	static NSString* versionDirectory;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString* version = [NSString stringWithFormat:@"%d", (int)[self applicationVersion]];
		versionDirectory = [self.libraryDirectory stringByAppendingPathComponent:version];
	});
	return versionDirectory;
}

- (void) setupDirectory {
	NSString* version = [NSString stringWithFormat:@"%d", (int)[self applicationVersion]];
	
	NSFileManager* fileManager = [NSFileManager defaultManager];
//	[fileManager removeItemAtPath:self.libraryDirectory error:nil];
	
	for (NSString* fileName in [fileManager contentsOfDirectoryAtPath:self.libraryDirectory error:nil]) {
		if ([fileName isEqualToString:version])
			continue;
		else
			[fileManager removeItemAtPath:[self.libraryDirectory stringByAppendingPathComponent:fileName] error:nil];
	}
	BOOL isDirectory;
	if (![fileManager fileExistsAtPath:self.versionDirectory isDirectory:&isDirectory])
		[fileManager createDirectoryAtPath:self.versionDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	else if (!isDirectory) {
		[fileManager removeItemAtPath:self.libraryDirectory error:nil];
		[fileManager createDirectoryAtPath:self.versionDirectory withIntermediateDirectories:nil attributes:nil error:nil];
	}
	
	NSString* currentBuild = [NSString stringWithFormat:@"%d", [[[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType] version].build];
	//currentBuild = @"912412";
	for (NSString* fileName in [fileManager contentsOfDirectoryAtPath:self.versionDirectory error:nil]) {
		if ([fileName isEqualToString:currentBuild] || [[fileName pathExtension] isEqualToString:@"record"])
			continue;
		else
			[fileManager removeItemAtPath:[self.versionDirectory stringByAppendingPathComponent:fileName] error:nil];
	}
}

- (UIViewController*) presentedViewController {
	UIViewController* root = [UIApplication sharedApplication].delegate.window.rootViewController;
	for(;root.presentedViewController; root = root.presentedViewController);
	return root;
}

- (void) downloadUpdateWithRecord:(CKRecord*) record {
	if (self.fetchRecordsOperation)
		return;
	
	self.state = NCUpdaterStateDownloading;
	NSString* downloadRecordPath = [self.versionDirectory stringByAppendingPathComponent:@"download.record"];
	[NSKeyedArchiver archiveRootObject:record toFile:downloadRecordPath];
	
	self.fetchRecordsOperation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[record.recordID]];
	self.fetchRecordsOperation.qualityOfService = NSQualityOfServiceBackground;
	self.progress.completedUnitCount = 0;
	[self.progress becomeCurrentWithPendingUnitCount:1];
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:100];
	[self.progress resignCurrent];
	
	[[self fetchRecordsOperation] setPerRecordProgressBlock:^(CKRecordID * record, double p) {
		progress.completedUnitCount = p * 100;
	}];
	
	[[self fetchRecordsOperation] setPerRecordCompletionBlock:^(CKRecord * _Nullable record, CKRecordID * __nullable recordID, NSError* error) {
		if (error || !record) {
			dispatch_async(dispatch_get_main_queue(), ^{
				UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to download database update", nil) message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
				[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Close", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
				}]];
				[self.presentedViewController presentViewController:controller animated:YES completion:nil];
				self.state = NCUpdaterStateWaitingForDownload;
				[[NSFileManager defaultManager] removeItemAtPath:downloadRecordPath error:nil];
			});
		}
		else {
			[NSKeyedArchiver archiveRootObject:record toFile:downloadRecordPath];
			CKAsset* eufe = record[@"eufe"];
			CKAsset* database = record[@"database"];
			database = eufe;
			if (eufe && database)
				[self installUpdateWithRecord:record];
		}
	}];
	
	[[self fetchRecordsOperation] setCompletionBlock:^{
		self.fetchRecordsOperation = nil;
	}];
	
	[self.database addOperation:self.fetchRecordsOperation];
}

- (void) installUpdateWithRecord:(CKRecord*) record {
	self.state = NCUpdaterStateInstalling;
	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	NSString* downloadRecordPath = [self.versionDirectory stringByAppendingPathComponent:@"download.record"];
	[fileManager removeItemAtPath:downloadRecordPath error:nil];
	
	NSString* databaseBuild = [NSString stringWithFormat:@"%@", record[@"build"]];
	NSString* tmp = [[self.versionDirectory stringByAppendingPathComponent:@"_"] stringByAppendingPathExtension:databaseBuild];
	if ([fileManager fileExistsAtPath:tmp isDirectory:NULL])
		[fileManager removeItemAtPath:tmp error:nil];
	[fileManager createDirectoryAtPath:tmp withIntermediateDirectories:YES attributes:nil error:nil];
	
	CKAsset* eufe = record[@"eufe"];
	CKAsset* database = record[@"database"];
	database = eufe;
	[self.progress becomeCurrentWithPendingUnitCount:1];
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:2];
	[self.progress resignCurrent];
	
	dispatch_queue_t queue = dispatch_queue_create(nil, 0);
	dispatch_async(queue, ^{
		NSString* eufeDst = [tmp stringByAppendingPathComponent:@"eufe.sqlite"];
		NSString* databaseDst = [tmp stringByAppendingPathComponent:@"NCDatabase.sqlite"];
		//NSString* eufeSrc = @"/Users/shimanski/Documents/git/EVEUniverse/dbTools/dbinit/eufe.sqlite.gz";
		//NSString* databaseSrc = @"/Users/shimanski/Documents/git/EVEUniverse/dbTools/dbinit/NCDatabase2.sqlite.gz";
		NSString* eufeSrc = eufe.fileURL.path;
		NSString* databaseSrc = database.fileURL.path;
		[progress becomeCurrentWithPendingUnitCount:1];
		NSError* error;
		[self decompressFileAtPath:eufeSrc toPath:eufeDst error:&error];
		[progress resignCurrent];
		if (!error) {
			[progress becomeCurrentWithPendingUnitCount:1];
			[self decompressFileAtPath:databaseSrc toPath:databaseDst error:&error];
			[progress resignCurrent];
			if (!error) {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSString* dst = [self.versionDirectory stringByAppendingPathComponent:databaseBuild];
					[fileManager removeItemAtPath:dst error:nil];
					[fileManager moveItemAtPath:tmp toPath:dst error:nil];
					[[NCDatabase sharedDatabase] reconnect];
					[[NSNotificationCenter defaultCenter] postNotificationName:NCDatabaseDidInstallUpdateNotification object:nil];
					UIAlertController* controller = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ update is installed", nil), record[@"title"]] message:nil preferredStyle:UIAlertControllerStyleAlert];
					[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					}]];
					self.state = NCUpdaterStateIsUpToDate;
					[self.presentedViewController presentViewController:controller animated:YES completion:nil];
				});
			}
			else
				self.state = NCUpdaterStateWaitingForDownload;
		}
		else
			self.state = NCUpdaterStateWaitingForDownload;
		[fileManager removeItemAtPath:eufeSrc error:nil];
		[fileManager removeItemAtPath:databaseSrc error:nil];
		self.error = error;
	});
}


- (BOOL) decompressFileAtPath:(NSString*) srcPath toPath:(NSString*) dstPath error:(NSError* _Nullable * _Nullable) error {
	const int CHUNK = 102400;

	int ret;
	unsigned have;
	z_stream strm;
	unsigned char* in = malloc(CHUNK);
	unsigned char* out = malloc(CHUNK);
	
	NSInteger fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:srcPath error:nil][NSFileSize] integerValue];
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:fileSize];
	
	NSInputStream* input = [NSInputStream inputStreamWithFileAtPath:srcPath];
	NSOutputStream* output = [NSOutputStream outputStreamToFileAtPath:dstPath append:YES];
	[input open];
	[output open];
	
	/* allocate inflate state */
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.avail_in = 0;
	strm.next_in = Z_NULL;
	ret = inflateInit2(&strm, 15+32);
	
	if (ret == Z_OK) {
		/* decompress until deflate stream ends or end of file */
		do {
			strm.avail_in = (int) [input read:in maxLength:CHUNK];
			if (strm.avail_in == 0)
				break;
			strm.next_in = in;
			progress.completedUnitCount += strm.avail_in;

			/* run inflate() on input until output buffer not full */
			do {
				strm.avail_out = CHUNK;
				strm.next_out = out;
				ret = inflate(&strm, Z_NO_FLUSH);
				switch (ret) {
					case Z_NEED_DICT:
					case Z_MEM_ERROR:
						ret = Z_DATA_ERROR;     /* and fall through */
					case Z_DATA_ERROR:
						inflateEnd(&strm);
						break;
				}
				if (ret != Z_DATA_ERROR) {
					have = CHUNK - strm.avail_out;
					[output write:out maxLength:have];
				}
			}
			while (strm.avail_out == 0 && ret != Z_DATA_ERROR);
			
		}
		while (ret != Z_STREAM_END && ret != Z_DATA_ERROR);
		inflateEnd(&strm);
	}
	[input close];
	[output close];
	free(in);
	free(out);
	if (ret != Z_STREAM_END) {
		[[NSFileManager defaultManager] removeItemAtPath:dstPath error:nil];
		if (error)
			*error = [NSError errorWithDomain:@"NCUpdater" code:0 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unable to install update", nil)}];
		return NO;
	}
	else
		return YES;
}

@end
