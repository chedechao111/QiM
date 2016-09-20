//
//  FAWAftertreatmentDataStreamViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-9.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWAftertreatmentDataStreamViewController.h"

@interface FAWAftertreatmentDataStreamViewController ()

@end

@implementation FAWAftertreatmentDataStreamViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.contentTextsArray = [NSMutableArray arrayWithObjects:@"压力管加热器状态", @"尿素箱加热电磁阀状态", @"回流管加热器反馈电压", @"吸入管加热器反馈电压", @"后处理加热主继电器状态", @"尿素泵压力传感器电压", @"尿素液位传感器电压", @"尿素溶液温度", @"排气温度", @"NOX浓度", @"尿素泵占空比", @"尿素喷射阀占空比", nil];
        
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
    self.navigationItem.title = @"后处理数据流";
    
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
            [self.contentValuesArray addObject:@"等待获取"];
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
    
    unsigned short identifiers[] = {0x4009, 0x400a, 0x400d, 0x400f, 0x4010, 0x4012, 0x4013, 0x4014, 0x4015, 0x4033, 0x403b, 0x403c};
    
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
        
        switch (self.dataIndex)
        {
            case 0:
            case 1:
            case 2:
            case 3:
            case 4:
            {
                text = @"暂不支持";
                break;
            }
            case 5:
            case 6:
            {
                double number = (NSInteger)((bytes[0] << 8) + bytes[1]) * 0.2;
                text = [NSString stringWithFormat:@"%.2f mV", number];
                break;
            }
            case 7:
            case 8:
            {
                double number = (NSInteger)((bytes[0] << 8) + bytes[1]) * 0.1 - 273.14;
                text = [NSString stringWithFormat:@"%.2f ℃", number];
                break;
            }
            case 9:
            {
                double number = (NSInteger)((bytes[0] << 8) + bytes[1]);
                text = [NSString stringWithFormat:@"%.2f ppm", number];
                break;
            }
            case 10:
            case 11:
            {
                double number = (NSInteger)((bytes[0] << 8) + bytes[1]) * 0.01;
                text = [NSString stringWithFormat:@"%.2f %%", number];
                break;
            }
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
