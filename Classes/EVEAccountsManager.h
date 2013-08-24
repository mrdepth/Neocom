//
//  EVEAccountsManager.h
//  EVEUniverse
//
//  Created by TANYA on 18.07.13.
//
//

#import <Foundation/Foundation.h>
#import "EVEAccount.h"

#define EVEAccountsManagerDidChangeNotification @"EVEAccountsManagerDidChangeNotification"
#define EVEAccountsManagerInsertedObjectsKey @"EVEAccountsManagerInsertedObjectsKey"
#define EVEAccountsManagerDeletedObjectsKey @"EVEAccountsManagerDeletedObjectsKey"
#define EVEAccountsManagerUpdatedObjectsKey @"EVEAccountsManagerUpdatedObjectsKey"

@interface EVEAccountsManager : NSObject
@property (nonatomic, strong) NSArray* allAccounts;

+ (EVEAccountsManager*) sharedManager;
+ (void) setSharedManager:(EVEAccountsManager*) manager;
- (void) reload;

- (EVEAccount*) accountWithCharacterID:(NSInteger) characterID;
- (BOOL) addAPIKeyWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr;
- (void) removeAPIKeyWithKeyID:(NSInteger) keyID;
- (void) ignoreCharacter:(NSInteger) characterID;
- (void) unignoreCharacter:(NSInteger) characterID;

@end
