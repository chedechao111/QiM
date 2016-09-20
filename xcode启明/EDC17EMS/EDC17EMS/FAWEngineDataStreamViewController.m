//
//  FAWEngineDataStreamViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-2.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWEngineDataStreamViewController.h"

@interface FAWEngineDataStreamViewController ()

@end

@implementation FAWEngineDataStreamViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.contentTextsArray = [NSMutableArray arrayWithObjects:@"发动机转速", @"发动机冷却液温度", @"机油压力值", @"车辆速度", @"同步状态", @"MIL请求状态", @"SVS请求状态", @"加速踏板采集电压1", @"加速踏板采集电压2", @"加速踏板开度", @"轨压传感器电压值", @"油轨压力当前值", @"油轨压力目标值", @"大气压力", @"进气压力值", @"进气温度值", @"远程加速踏板1电压", @"远程加速踏板2电压", @"远程油门踏板位置", @"油量计量单元开度", @"油量计量单元电压", @"当前喷油量", nil];
        
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
    self.navigationItem.title = @"发动机数据流";
    
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
    
    unsigned short identifiers[] = {0x015e, 0x0164, 0x0168, 0x0126, 0x0161, 0x0221, 0x0222, 0x0107, 0x0108, 0x010b, 0x0183, 0x0185, 0x0186, 0x020b, 0x020e, 0x0211, 0x0144, 0x0145, 0x147, 0x176, 0x0178, 0x0194};
    
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
            {
                double number = (NSInteger)((bytes[0] << 8) + bytes[1]) * 0.5;
                text = [NSString stringWithFormat:@"%.2f rpm", number];
                break;
            }
            case 1:
            case 15:
            {
                double numver = (NSInteger)((bytes[0] << 8) + bytes[1]) * 0.1 - 273.14;
                text = [NSString stringWithFormat:@"%.2f ℃", numver];
                break;
            }
            case 2:
            case 13:
            case 14:
            {
                double number = (NSInteger)((bytes[0] << 8) + bytes[1]);
                text = [NSString stringWithFormat:@"%.2f hPa", number];
                break;
            }
            case 3:
            {
                double number = (NSInteger)((bytes[0] << 8) + bytes[1]) * 0.01;
                text = [NSString stringWithFormat:@"%.2f km/h", number];
                break;
            }
            case 4:
            {
                Byte number = bytes[0];
                
                switch (number)
                {
                    case 0:
                        text = @"EPM_NO_SYNC";
                        break;
                    case 10:
                        text = @"EPM_ALE_SYNC";
                        break;
                    case 20:
                        text = @"EPM_CAS_SYNC";
                        break;
                    case 21:
                        text = @"EPM_DIRSTALE_SYNC";
                        break;
                    case 30:
                        text = @"EPM_FULL_SYNC";
                        break;
                    default:
                        text = @"未知";
                        break;
                }
            
                break;
            }
            case 5:
            case 6:
            {
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
                
                break;
            }
            case 7:
            case 8:
            case 10:
            case 16:
            case 17:
            case 20:
            {
                double number = (NSInteger)((bytes[0] << 8) + bytes[1]) * 0.2;
                text = [NSString stringWithFormat:@"%.2f mV", number];
                break;
            }
            case 9:
            case 18:
            {
                double number = (NSInteger)((bytes[0] << 8) + bytes[1]) * 0.012207;
                text = [NSString stringWithFormat:@"%.2f %%", number];
                break;
            }
            case 11:
            case 12:
            {
                double number = (NSInteger)((bytes[0] << 8) + bytes[1]) * 100;
                text = [NSString stringWithFormat:@"%.2f hPa", number];
                break;
            }
            case 19:
            {
                double numer = (NSInteger)((bytes[0] << 8) + bytes[1]) * 0.01;
                text = [NSString stringWithFormat:@"%.2f %%", numer];
                break;
            }
            case 21:
            {
                double number = (NSInteger)((bytes[0] << 8) + bytes[1]) * 0.02;
                text = [NSString stringWithFormat:@"%.2f mg/hub", number];
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
