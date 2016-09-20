//
//  FAWExternalTestViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-4.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "FAWCompressionTestViewController.h"
#import "FAWHiPotTestViewController.h"
#import "FAWRunUpTestViewController.h"
#import "FAWSprayShutoffTestViewController.h"
#import "FAWSpeedCompareTestViewController.h"
#import "FAWStartupFaultTestViewController.h"
#import "FAWExternalTestViewController.h"

@interface FAWExternalTestViewController ()

@end

@implementation FAWExternalTestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.menuTextsArray = [NSMutableArray arrayWithObjects:@"压缩测试", @"高压测试", @"加速测试", @"断缸测试", @"转速比较测试", @"读取启动故障信息", nil];
        self.menuControllersArray = [NSMutableArray arrayWithObjects:[[FAWCompressionTestViewController alloc] initWithNibName:@"FAWCompressionTestViewController" bundle:nil], [[FAWHiPotTestViewController alloc] initWithNibName:@"FAWHiPotTestViewController" bundle:nil], [[FAWRunUpTestViewController alloc] initWithNibName:@"FAWRunUpTestViewController" bundle:nil], [[FAWSprayShutoffTestViewController alloc] initWithNibName:@"FAWSprayShutoffTestViewController" bundle:nil], [[FAWSpeedCompareTestViewController alloc] initWithNibName:@"FAWSpeedCompareTestViewController" bundle:nil], [[FAWStartupFaultTestViewController alloc] initWithNibName:@"FAWStartupFaultTestViewController" bundle:nil], nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"外部测试";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
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
    tableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return tableViewCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController pushViewController:[self.menuControllersArray objectAtIndex:indexPath.row] animated:YES];
}

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
