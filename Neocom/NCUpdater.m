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
@property (nonatomic, retain) NSString* libraryDirectory;
@property (nonatomic, retain) NSString* versionDirectory;
@property (nonatomic, strong, readwrite) NSProgress* progress;

- (void) setupDirectory;
- (UIViewController*) presentedViewController;
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
		[self.progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:nil];
	}
	return self;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
	NSLog(@"%@", change[NSKeyValueChangeNewKey]);
}

- (NSInteger) applicationVersion {
	static NSInteger applicationVersion = 0;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		applicationVersion = [[[[NSBundle mainBundle] infoDictionary][(__bridge NSString*)kCFBundleVersionKey] pathExtension] integerValue];
		applicationVersion = 11856;
	});
	return applicationVersion;
}

- (void) checkUpdates {
	if (!self.database)
		self.database = [[CKContainer defaultContainer] publicCloudDatabase];
	
	int NCDatabaseBuild = [[[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType] version].build;
	
	if (self.fetchRecordsOperation) {
		return;
	}
	else {
		//Resume download/install
		NSFileManager* fileManager = [NSFileManager defaultManager];

		NSString* downloadRecordPath = [self.versionDirectory stringByAppendingPathComponent:@"Download.record"];
		CKRecord* downloadRecord = [NSKeyedUnarchiver unarchiveObjectWithFile:downloadRecordPath];
		if (downloadRecord) {
			int build = [downloadRecord[@"NCDatabaseBuild"] intValue];
			CKAsset* eufe = downloadRecord[@"eufe"];
			CKAsset* database = downloadRecord[@"NCDatabase"];
			database = eufe;
			
			if (build > NCDatabaseBuild) {
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
		CKQuery* query = [[CKQuery alloc] initWithRecordType:@"Database" predicate:[NSPredicate predicateWithFormat:@"CFBundleVersion == %d AND NCDatabaseBuild > %d", 11856, NCDatabaseBuild]];
		query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"NCDatabaseBuild" ascending:NO]];
		self.queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
		self.queryOperation.desiredKeys = @[@"NCDatabaseBuild", @"size"];
		self.queryOperation.resultsLimit = 1;
		self.queryOperation.qualityOfService = NSQualityOfServiceBackground;
		
		[[self queryOperation] setRecordFetchedBlock:^(CKRecord * _Nonnull record) {
			NSString* cachedRecordPath = [self.versionDirectory stringByAppendingPathComponent:@"Database.record"];
			[[NSFileManager defaultManager] removeItemAtPath:cachedRecordPath error:nil];
			CKRecord* cachedRecord = [NSKeyedUnarchiver unarchiveObjectWithFile:cachedRecordPath];
			if (cachedRecord && [cachedRecord[@"NCDatabaseBuild"] isEqual:record[@"NCDatabaseBuild"]]) {
			}
			else {
				[NSKeyedArchiver archiveRootObject:record toFile:cachedRecordPath];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"New database update available", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Would you like to update?\nSize: %.1fMB", nil), [record[@"size"] floatValue] / 1024 / 1024] preferredStyle:UIAlertControllerStyleAlert];
					[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Download and Update", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
						[self downloadUpdateWithRecord:record];
					}]];
					[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Not now", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
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

- (void) installUpdateWithRecord:(CKRecord*) record {
	NSString* databaseBuild = [NSString stringWithFormat:@"%@", record[@"NCDatabaseBuild"]];
	NSString* tmp = [[self.versionDirectory stringByAppendingPathComponent:@"_"] stringByAppendingPathExtension:databaseBuild];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:tmp isDirectory:NULL])
		[fileManager removeItemAtPath:tmp error:nil];
	[fileManager createDirectoryAtPath:tmp withIntermediateDirectories:YES attributes:nil error:nil];
	
	CKAsset* eufe = record[@"eufe"];
	CKAsset* database = record[@"NCDatabase"];
	database = eufe;
	[self.progress becomeCurrentWithPendingUnitCount:1];
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:2];
	[self.progress resignCurrent];
	
	dispatch_queue_t queue = dispatch_queue_create(nil, 0);
	dispatch_async(queue, ^{
		NSString* eufeDst = [tmp stringByAppendingPathComponent:@"eufe.sqlite"];
		NSString* databaseDst = [tmp stringByAppendingPathComponent:@"NCDatabase.sqlite"];
		//NSString* eufeSrc = @"/Users/shimanski/work/git/EVEUniverse/dbTools/dbinit/eufe.sqlite.gz";
		//NSString* databaseSrc = @"/Users/shimanski/work/git/EVEUniverse/dbTools/dbinit/NCDatabase.sqlite.gz";
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
				[fileManager moveItemAtPath:tmp toPath:[self.versionDirectory stringByAppendingPathComponent:databaseBuild] error:nil];
			}
		}
		[fileManager removeItemAtPath:eufeSrc error:nil];
		[fileManager removeItemAtPath:databaseSrc error:nil];
		self.error = error;
	});
}

- (void) downloadUpdateWithRecord:(CKRecord*) record {
	NSString* downloadRecordPath = [self.versionDirectory stringByAppendingPathComponent:@"Download.record"];
	[NSKeyedArchiver archiveRootObject:record toFile:downloadRecordPath];
	
	self.fetchRecordsOperation = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[record.recordID]];
	self.fetchRecordsOperation.qualityOfService = NSQualityOfServiceBackground;
	self.progress.completedUnitCount = 0;
	[self.progress becomeCurrentWithPendingUnitCount:1];
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:100];
	[self.progress resignCurrent];
	
	[[self fetchRecordsOperation] setPerRecordProgressBlock:^(CKRecordID * record, double p) {
		progress.completedUnitCount = p * 100;
//		NSLog(@"%f", (float) p);
	}];
	
	[[self fetchRecordsOperation] setPerRecordCompletionBlock:^(CKRecord * _Nullable record, CKRecordID * __nullable recordID, NSError* error) {
		if (error || !record) {
			dispatch_async(dispatch_get_main_queue(), ^{
				UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to download database update", nil) message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
				[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Close", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
				}]];
				[self.presentedViewController presentViewController:controller animated:YES completion:nil];
				
			});
		}
		else {
			[NSKeyedArchiver archiveRootObject:record toFile:downloadRecordPath];
			CKAsset* eufe = record[@"eufe"];
			CKAsset* database = record[@"NCDatabase"];
			database = eufe;
			if (eufe && database)
				[self installUpdateWithRecord:record];
		}
	}];
	
	[self.database addOperation:self.fetchRecordsOperation];
}

#pragma mark - Private

- (NSString*) libraryDirectory {
	return [NCDatabase libraryDirectory];
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
	[fileManager removeItemAtPath:self.libraryDirectory error:nil];
	
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
}

- (UIViewController*) presentedViewController {
	UIViewController* root = [UIApplication sharedApplication].delegate.window.rootViewController;
	for(;root.presentedViewController; root = root.presentedViewController);
	return root;
}

- (BOOL) decompressFileAtPath:(NSString*) srcPath toPath:(NSString*) dstPath error:(NSError* _Nullable * _Nullable) error {
	const int CHUNK = 1024;

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
