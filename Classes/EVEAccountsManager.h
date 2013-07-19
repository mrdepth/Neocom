//
//  EVEAccountsManager.h
//  EVEUniverse
//
//  Created by TANYA on 18.07.13.
//
//

#import <Foundation/Foundation.h>
#import "EVEAccount.h"
@interface EVEAccountsManager : NSObject
@property (nonatomic, strong) NSArray* allAccounts;

+ (EVEAccountsManager*) sharedManager;
- (void) reload;

- (BOOL) addAPIKeyWithKeyID:(NSInteger) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr;
- (void) removeAPIKeyWithKeyID:(NSInteger) keyID;

@end
