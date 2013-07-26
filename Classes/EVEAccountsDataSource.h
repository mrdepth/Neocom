//
//  EVEAccountsDataSource.h
//  EVEUniverse
//
//  Created by mr_depth on 19.07.13.
//
//

#import <UIKit/UIKit.h>

@interface EVEAccountsDataSource : NSObject<UICollectionViewDataSource>
@property (nonatomic, copy) NSString* nibName;
@property (nonatomic, copy) NSString* reuseIdentifier;
@property (nonatomic, weak) IBOutlet UICollectionView* collectionView;
@property (nonatomic, weak) IBOutlet UIViewController* viewController;
@property (nonatomic, strong) NSArray* accounts;
@property (nonatomic, strong) NSArray* apiKeys;
@property (nonatomic, assign) BOOL editing;

- (void) setEditing:(BOOL)editing animated:(BOOL)animated;
- (void) reload;

@end
