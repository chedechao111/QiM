//
//  FAWFaultDiagnosisViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-5.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWPendingFaultViewController.h"
#import "FAWConfirmedFaultViewController.h"
#import "FAWFaultDiagnosisViewController.h"

@interface FAWFaultDiagnosisViewController ()

@end

@implementation FAWFaultDiagnosisViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.menuTextsArray = [NSMutableArray arrayWithObjects:@"获取当前故障", @"获取历史故障", @"清除全部故障", nil];
        self.menuControllersArray = [NSMutableArray arrayWithObjects:[[FAWPendingFaultViewController alloc] initWithNibName:@"FAWPendingFaultViewController" bundle:nil], [[FAWConfirmedFaultViewController alloc] initWithNibName:@"FAWConfirmedFaultViewController" bundle:nil], nil];
        
        self.businessLayer = ((FAWAppDelegate *)[[UIApplication sharedApplication] delegate]).businessLayer;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"故障诊断";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
    self.noticeActionSheet = [[UIActionSheet alloc] initWithTitle:@"      清除全部故障将清除全部发动机故障(包括发动机当前故障及发动机历史故障), 并且清除过程不可恢复, 您确定要清除发动机故障吗?" delegate:self cancelButtonTitle:@"我按错了, 请取消" destructiveButtonTitle:@"我已了解, 请继续" otherButtonTitles: nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSIndexPath * selectedIndexPath = self.menuTableView.indexPathForSelectedRow;
    [self.menuTableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.menuTextsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * tableViewCell = [self.menuTableView dequeueReusableCellWithIdentifier:@"MenuTableViewCell"];
    
    if (tableViewCell == nil)
    {
        tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MenuTableViewCell"];
    }
    
    tableViewCell.textLabel.text = [self.menuTextsArray objectAtIndex:indexPath.row];
    
    if (indexPath.row != 2)
    {
        tableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        tableViewCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return tableViewCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != 2)
    {
        [self.navigationController pushViewController:[self.menuControllersArray objectAtIndex:indexPath.row] animated:YES];
    }
    else
    {
        [self.noticeActionSheet showInView:self.view];
    }
}

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.menuTableView deselectRowAtIndexPath:[self.menuTableView indexPathForSelectedRow] animated:YES];
    
    if (buttonIndex != 0)
    {
        return;
    }
    
    self.navigationItem.leftBarButtonItem.enabled = NO;
    
    [SVProgressHUD showWithStatus:@"正在清除故障, 请稍后..." maskType:SVProgressHUDMaskTypeClear];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self asyncWorkStarted];
                   });
}

- (void)asyncWorkStarted
{
    Error error = Success;
    
    error = [self.businessLayer prepareOperation];
    
    if (error != Success)
    {
        goto theEnd;
    }

    error = [self.businessLayer clearDTC];
    
theEnd:
    
    dispatch_sync(dispatch_get_main_queue(),
                  ^{
                      if (error == Success)
                      {
                          [SVProgressHUD showSuccessWithStatus:@"故障清除成功."];
                      }
                      else
                      {
                          [SVProgressHUD showErrorWithStatus:[self.businessLayer getErrorMessage:error]];
                      }
                      
                      self.navigationItem.leftBarButtonItem.enabled = YES;
                      
                      return;
                  });
}

@end
