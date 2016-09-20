//
//  FAWLoginViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-6-29.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "FAWAppDelegate.h"
#import "FAWMainViewController.h"
#import "FAWLoginViewController.h"

@interface FAWLoginViewController ()

@end

@implementation FAWLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.radioNormalImage = [UIImage imageNamed:@"RadioNormal.png"];
        self.radioSelectedImage = [UIImage imageNamed:@"RadioSelected.png"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.normalUserButton setImage:self.radioSelectedImage forState:UIControlStateNormal];
    [self.preniumUserButton setImage:self.radioNormalImage forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)normalUserButtonPressed:(id)sender
{
    [self.normalUserButton setImage:self.radioSelectedImage forState:UIControlStateNormal];
    [self.preniumUserButton setImage:self.radioNormalImage forState:UIControlStateNormal];
    
    ((FAWAppDelegate *)[UIApplication sharedApplication].delegate).userPrivilege = 1;
}

- (IBAction)preniumUserButtonPressed:(id)sender
{
    [self.normalUserButton setImage:self.radioNormalImage forState:UIControlStateNormal];
    [self.preniumUserButton setImage:self.radioSelectedImage forState:UIControlStateNormal];
    ((FAWAppDelegate *)[UIApplication sharedApplication].delegate).userPrivilege = 0;
}

- (IBAction)loginButtonPressed:(id)sender {
    
    FAWMainViewController * mainViewController = [[FAWMainViewController alloc] initWithNibName:@"FAWMainViewController" bundle:nil];
    
    UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (IBAction)clearButtonPressed:(id)sender {
    self.passwordTextField.text = nil;
}
@end
