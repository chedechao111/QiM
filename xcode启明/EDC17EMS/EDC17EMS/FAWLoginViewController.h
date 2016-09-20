//
//  FAWLoginViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-6-29.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FAWLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *normalUserButton;
@property (weak, nonatomic) IBOutlet UIButton *preniumUserButton;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
- (IBAction)normalUserButtonPressed:(id)sender;
- (IBAction)preniumUserButtonPressed:(id)sender;
- (IBAction)loginButtonPressed:(id)sender;
- (IBAction)clearButtonPressed:(id)sender;
@property (strong, nonatomic) UIImage * radioNormalImage;
@property (strong, nonatomic) UIImage * radioSelectedImage;

@end
