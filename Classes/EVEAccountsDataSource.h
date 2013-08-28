//
//  EVEAccountsDataSource.h
//  EVEUniverse
//
//  Created by mr_depth on 19.07.13.
//
//

#import <UIKit/UIKit.h>
#import "ASCollectionView.h"

@interface EVEAccountsDataSource : NSObject<ASCollectionViewDataSource>
@property (nonatomic, copy) NSString* nibName;
@property (nonatomic, copy) NSString* reuseIdentifier;
@property (nonatomic, weak) IBOutlet ASCollectionView* collectionView;
@property (nonatomic, weak) IBOutlet UIViewController* viewController;
@property (nonatomic, strong) NSMutableArray* accounts;
@property (nonatomic, strong) NSMutableArray* allAccounts;
@property (nonatomic, strong) NSArray* apiKeys;
@property (nonatomic, assign) BOOL editing;
@property (nonatomic, strong) NSArray* selectedAccounts;

- (void) setEditing:(BOOL)editing animated:(BOOL)animated;
- (void) reloadWithCompletionHandler:(void(^)()) completionHandler;

@end
