//
//  NCMenuViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 08.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMenuViewController.h"

@interface NCMenuEmbedSegue : UIStoryboardSegue

@end

@implementation NCMenuEmbedSegue

- (void) perform {
    NSLog(@"%@ %@", self.sourceViewController, self.destinationViewController);
    NCMenuViewController* menuViewController = (NCMenuViewController*) self.sourceViewController;
    UIViewController* destinationViewController = self.destinationViewController;
    [menuViewController.view addSubview:destinationViewController.view];
    
    CGRect frame = menuViewController.view.bounds;
    frame.origin.x = frame.size.width - 40;
    destinationViewController.view.frame = frame;
    
//    destinationViewController.view.clipsToBounds = NO;
//    destinationViewController.view.layer.shadowOffset = CGSizeMake(-0, 0);
//    destinationViewController.view.layer.shadowOpacity = 1.0;
    menuViewController.contentViewController = destinationViewController;
}

@end

@interface NCMenuViewController ()

@end

@implementation NCMenuViewController

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
    [self performSegueWithIdentifier:@"ContentViewController" sender:self];
    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)]];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Embed"]) {
        self.menuViewController = segue.destinationViewController;
    }
}

- (void) onPan:(UIPanGestureRecognizer*) recognizer {
    CGAffineTransform transform = CGAffineTransformMakeTranslation([recognizer translationInView:self.view].x, 0);
    self.contentViewController.view.transform = transform;
}

@end
