//
//  NCCharacter.m
//  Develop
//
//  Created by Artem Shimanski on 21.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCharacter.h"
#import "NCDataManager.h"

@interface NCCharacter()
@property (nonatomic, strong, readwrite) NCCharacterAttributes* characterAttributes;
@property (nonatomic, strong, readwrite) NSArray<NCSkill*>* skills;
@property (nonatomic, strong, readwrite) NCTrainingQueue* skillQueue;
@end

@implementation NCCharacter

+ (void) createCharacterForAccount:(NCAccount*) account completinHandler:(void (^)(NCCharacter* character, NSError* error)) block {
	if (!account || account.eveAPIKey.corporate) {
		block([NCCharacter new], nil);
	}
	else {
		dispatch_group_t dispatchGroup = dispatch_group_create();
		
		
		__block EVECharacterSheet* characterSheet;
		__block NSError* err;
		dispatch_group_enter(dispatchGroup);
		[[NCDataManager defaultManager] characterSheetForAccount:account cachePolicy:NSURLRequestReturnCacheDataElseLoad completionHandler:^(EVECharacterSheet *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			characterSheet = result;
			if (error)
				err = error;
			dispatch_group_leave(dispatchGroup);
		}];
		
		__block EVESkillQueue* skillQueue;
		dispatch_group_enter(dispatchGroup);
		[[NCDataManager defaultManager] skillQueueForAccount:account cachePolicy:NSURLRequestReturnCacheDataElseLoad completionHandler:^(EVESkillQueue *result, NSError *error, NSManagedObjectID *cacheRecordID) {
			skillQueue = result;
			dispatch_group_leave(dispatchGroup);
		}];
		
		dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
			if (characterSheet) {
				[[NCDatabase sharedDatabase] performBackgroundTask:^(NSManagedObjectContext *managedObjectContext) {
					NCFetchedCollection<NCDBInvType*>* invTypes = [NCDBInvType invTypesWithManagedObjectContext:managedObjectContext];
					NSMutableDictionary* queue = [NSMutableDictionary new];
					for (EVESkillQueueItem *item in [skillQueue.skillQueue sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"queuePosition" ascending:YES]]]) {
						if (item.endTime && item.startTime) {
							EVESkillQueueItem* s = queue[@(item.typeID)];
							if (!s)
								queue[@(item.typeID)] = s;
						}
					}
					
					NSMutableArray* skills = [NSMutableArray new];
					for (EVECharacterSheetSkill* characterSkill in characterSheet.skills) {
						EVESkillQueueItem* item = queue[@(characterSkill.typeID)];
						NCSkill* skill = [[NCSkill alloc] initWithInvType:invTypes[characterSkill.typeID]];
						if (skill) {
							if (item && item.queuePosition == 0) {
								skill.skillPoints = item.startSP;
								skill.trainingStartDate = [skillQueue.eveapi localTimeWithServerTime:item.startTime];
							}
						}
						[skills addObject:skill];
					}
					
					NCCharacter* character = [NCCharacter new];
					characterSheet.skills = skills;
					character.characterAttributes = [NCCharacterAttributes characterAttributesWithCharacterSheet:characterSheet];
					character.skillQueue = [[NCTrainingQueue alloc] initWithSkillQueue:skillQueue];
					dispatch_async(dispatch_get_main_queue(), ^{
						block(character, nil);
					});
				}];
			}
			else
				block(nil, err);
		});
	}
}

@end
