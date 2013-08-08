//
//  FitCharacter.h
//  EVEUniverse
//
//  Created by mr_depth on 08.08.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Character.h"

typedef enum : int16_t {
	FitCharacterTypeCustom,
	FitCharacterTypeAccount
} FitCharacterType;

@class EVEAccount;
@interface FitCharacter : NSManagedObject<Character>

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * skills;
@property (nonatomic) FitCharacterType type;

@property (nonatomic, strong) EVEAccount* account;

+ (NSArray*) allCustomCharacters;
+ (FitCharacter*) fitCharacterWithAccount:(EVEAccount*) account;
- (void) save;

@end
