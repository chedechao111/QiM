//
//  FAWVehicleDataStreamViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-3.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWVehicleDataStreamViewController.h"

@interface FAWVehicleDataStreamViewController ()

@end

@implementation FAWVehicleDataStreamViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.contentTextsArray = [NSMutableArray arrayWithObjects:@"ON挡开关", @"起动机继电器控制信号", @"主刹车开关", @"冗余刹车开关", @"刹车开关状态", @"发动机制动开关状态", @"驻车制动开关", @"离合器开关", @"空挡开关", @"空调开关", @"进气预热状态", @"预热指示灯", @"巡航开关+状态", @"巡航开关-状态", @"巡航开关OFF状态", @"巡航开关RESUME状态", @"PTO开关状态", nil];
        
        self.businessLayer = ((FAWAppDelegate *)[[UIApplication sharedApplication] delegate]).businessLayer;
        
        self.isNowWorking = NO;
        self.dataIndex = -1;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.contentValuesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.contentTextsArray count]; ++i)
    {
        [self.contentValuesArray addObject:@"等待获取"];
    }
    
    [self.contentTableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"整车数据流";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"获取" style:UIBarButtonItemStylePlain target:self action:@selector(actButtonPressed:)];
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
    return [self.contentTextsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * tableViewCell = [self.contentTableView dequeueReusableCellWithIdentifier:@"ContentTableViewCell"];
    
    if (tableViewCell == nil)
    {
        tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ContentTableViewCell"];
        tableViewCell.accessoryView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    tableViewCell.textLabel.text = [self.contentTextsArray objectAtIndex:indexPath.row];
    tableViewCell.detailTextLabel.text = [self.contentValuesArray objectAtIndex:indexPath.row];
    
    UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)tableViewCell.accessoryView;
    
    if (self.dataIndex == indexPath.row)
    {
        activityIndicatorView.hidden = NO;
        [activityIndicatorView startAnimating];
    }
    else
    {
        [activityIndicatorView stopAnimating];
        activityIndicatorView.hidden = YES;
    }
    
    return tableViewCell;
}

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actButtonPressed:(id)sender
{
    if (!self.isNowWorking)
    {
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.title = @"停止";
        
        self.contentValuesArray = [[NSMutableArray alloc] init];
        
        for (NSInteger i = 0; i < [self.contentTextsArray count]; ++i)
        {
            [self.contentValuesArray addObject:@"等待检测"];
        }
        
        [self.contentTableView reloadData];
        
        self.isNowWorking = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{
                           [self asyncWorkStarted];
                       });
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        [SVProgressHUD showWithStatus:@"正在停止, 请稍后..." maskType:SVProgressHUDMaskTypeBlack];
        
        self.isNowWorking = NO;
    }
}

- (void)asyncWorkStarted
{
    Error error = Success;
    
    NSData * data = nil;
    
    Byte * bytes = nil;
    
    NSString * text = nil;
    
    unsigned short identifiers[] = {0x0102, 0x0105, 0x010f, 0x0111, 0x0112, 0x0114, 0x011d, 0x011e, 0x011f, 0x0122, 0x0128, 0x012c, 0x0137, 0x0138, 0x0139, 0x013a, 0x0140};
    
    NSInteger dataCount = sizeof(identifiers) / sizeof(identifiers[0]);
    
    error = [self.businessLayer prepareOperation];
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    while (self.isNowWorking)
    {
        ++self.dataIndex;
        
        if (self.dataIndex >= dataCount)
        {
            self.dataIndex = 0;
        }
        
        dispatch_sync(dispatch_get_main_queue(),
                      ^{
                          UITableViewCell *tableViewCell = [self.contentTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataIndex inSection:0]];
                          UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)tableViewCell.accessoryView;
                          activityIndicatorView.hidden = NO;
                          [activityIndicatorView startAnimating];
                      });
        
        error = [self.businessLayer readData:&data byIdentifier:identifiers[self.dataIndex]];
        
        if (error != Success)
        {
            goto theEnd;
        }
        
        bytes = (Byte *)[data bytes];
        
        Byte number = bytes[0];
                
        switch (number)
        {
            case 0:
                text = @"打开";
                break;
            case 1:
                text = @"关闭";
                break;
            default:
                text = @"未知";
                break;
        }
        
        [self.contentValuesArray replaceObjectAtIndex:self.dataIndex withObject:text];
        
        dispatch_sync(dispatch_get_main_queue(),
                      ^{
                          UITableViewCell *tableViewCell = [self.contentTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataIndex inSection:0]];
                          UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)tableViewCell.accessoryView;
                          tableViewCell.detailTextLabel.text = text;
                          [activityIndicatorView stopAnimating];
                          activityIndicatorView.hidden = YES;
                      });
    }
    
theEnd:
    
    dispatch_sync(dispatch_get_main_queue(),
                  ^{
                      if (error != Success && self.isNowWorking)
                      {
                          [SVProgressHUD showErrorWithStatus:[self.businessLayer getErrorMessage:error]];
                      }
                      else
                      {
                          [SVProgressHUD dismiss];
                      }
                      
                      self.dataIndex = -1;
                      self.isNowWorking = NO;
                      
                      [self.contentTableView reloadData];
                      
                      self.navigationItem.leftBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.title = @"获取";
                  });
    
    return;
}

@end
