//
//  FAWAftertreatmentTestViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-11.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWAftertreatmentTestViewController.h"

@interface FAWAftertreatmentTestViewController ()

@end

@implementation FAWAftertreatmentTestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.contentTextsArray = [NSMutableArray arrayWithObjects:@"SCR外部测试状态", @"泵压力", @"实际喷射流量", @"泵占空比", @"转向阀状态", @"SCR系统主状态", @"SCR系统子状态", @"设定喷射流量", @"设定喷射量", @"实际喷射量", @"喷嘴开度", nil];
        
        self.businessLayer = ((FAWAppDelegate *)([[UIApplication sharedApplication] delegate])).businessLayer;
        
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
    self.navigationItem.title = @"后处理测试";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"测试" style:UIBarButtonItemStylePlain target:self action:@selector(actButtonPressed:)];
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
        
        self.isNowWorking = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{
                           [self asyncWorkStarted];
                       });
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        [SVProgressHUD showWithStatus:@"正在停止..."];
        
        self.isNowWorking = NO;
    }
}

- (void)asyncWorkStarted
{
    Error error = Success;
    
    //超时计数器
    NSInteger counter = 0;
    
    //测试过程中各个变量地址(以字节编码)
    Byte addresses[][3] =
    {
        {0x50, 0x25, 0x3f},     //SCR外部测试状态
        {0x50, 0x11, 0x30},     //泵压力
        {0x50, 0x12, 0x4c},     //实际喷射流量
        {0x50, 0x12, 0xa4},     //泵占空比
        {0x50, 0x25, 0xf7},     //转向阀状态
        {0x50, 0x1e, 0x1b},     //SCR系统主状态
        {0x50, 0x1e, 0x1f},     //SCR系统子状态
        {0x50, 0x10, 0xfe},     //设定喷射流量
        {0x50, 0x11, 0x06},     //设定喷射量
        {0x50, 0x11, 0x08},     //实际喷射量
        {0x50, 0x12, 0x68}      //喷嘴开度
    };
    
    //每个变量的长度
    NSInteger lengths[] = {1, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2};
    
    if (!self.isNowWorking)
    {
        error = Canceled;
        goto theEnd;
    }
    
    error = [self.businessLayer prepareOperation];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    //更改会话模式, 模式标识0x40
    error = [self.businessLayer changeSessionMode:0x40];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    //该测试需要认证安全访问策略
    error = [self.businessLayer passAccessLimit];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    //该例程标识为0x0322
    error = [self.businessLayer startRoutineControlByIdentifier:0x0322 withData:nil];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    while (YES)
    {
        error = [self.businessLayer getRoutineControlStatusByIdentifier:0x0322];
        
        if (!self.isNowWorking)
        {
            error = Canceled;
            goto  theEnd;
        }
        
        if (error == Success)
        {
            break;
        }
        
        if (error != RoutineControlFailure)
        {
            goto theEnd;
        }
        
        for (int i = 0; i < sizeof(addresses) / sizeof(addresses[0]); ++i)
        {
            NSData * data = nil;
            NSData * address = [NSData dataWithBytes:addresses[i] length:sizeof(addresses[i])];
            
            self.dataIndex = i;
            
            dispatch_sync(dispatch_get_main_queue(),
                          ^{
                              UITableViewCell *tableViewCell = [self.contentTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataIndex inSection:0]];
                              UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)tableViewCell.accessoryView;
                              activityIndicatorView.hidden = NO;
                              [activityIndicatorView startAnimating];
                          });

            
            error = [self.businessLayer readData:&data byAddress:address andLength:lengths[i]];
            
            if (error != Success)
            {
                goto theEnd;
            }
            
            Byte * bytes = (Byte *)[data bytes];
            
            NSString * texts = nil;
            
            switch (i)
            {
                case 0:
                {
                    if (bytes[0])
                    {
                        texts = @"关闭";
                    }
                    else
                    {
                        texts = @"打开";
                    }
                    
                    break;
                }
                case 1:
                {
                    double number = ((bytes[0] << 8) + bytes[1]);
                    
                    texts = [NSString stringWithFormat:@"%.2f hPa", number];
                    
                    break;
                }
                case 2:
                case 7:
                {
                    double number = ((bytes[0] << 8) + bytes[1]) * 0.1;
                    
                    texts = [NSString stringWithFormat:@"%.2f mg/s", number];
                    
                    break;
                }
                case 3:
                case 10:
                {
                    double number = ((bytes[0] << 8) + bytes[1] * 0.01);
                    
                    texts = [NSString stringWithFormat:@"%.2f %%", number];
                    
                    break;
                }
                case 4:
                {
                    if (bytes[0])
                    {
                        texts = @"关闭";
                    }
                    else
                    {
                        texts = @"打开";
                    }
                    
                    break;
                }
                case 5:
                {
                    switch (bytes[0])
                    {
                        case 0:
                            texts = @"SCR系统初始化";
                            break;
                        case 1:
                            texts = @"SCR系统待命";
                            break;
                        case 2:
                            texts = @"SCR系统无压力控制状态";
                            break;
                        case 3:
                            texts = @"SCR系统诊断";
                            break;
                        case 4:
                            texts = @"压力控制状态";
                            break;
                        case 5:
                            texts = @"压力降状态";
                            break;
                        case 6:
                            texts = @"倒抽状态";
                            break;
                        default:
                            texts = @"未知状态";
                            break;
                    }
                    
                    break;
                }
                case 6:
                {
                    switch (bytes[0])
                    {
                        case 0:
                            texts = @"系统初始化";
                            break;
                        case 1:
                            texts = @"ETC初始化";
                            break;
                        case 2:
                            texts = @"ETC1阶段";
                            break;
                        case 3:
                            texts = @"ETC2阶段";
                            break;
                        case 4:
                            texts = @"ETC3阶段";
                            break;
                        case 5:
                            texts = @"ETC4阶段";
                            break;
                        case 6:
                            texts = @"ETC5阶段";
                            break;
                        case 7:
                            texts = @"ETC6阶段";
                            break;
                        case 8:
                            texts = @"倒抽(等待)";
                            break;
                        case 9:
                            texts = @"倒抽(排空)";
                            break;
                        case 10:
                            texts = @"倒抽(补偿)";
                            break;
                        case 11:
                            texts = @"等待系统关闭";
                            break;
                        case 12:
                            texts = @"尿素加注";
                            break;
                        case 13:
                            texts = @"系统建压";
                            break;
                        case 14:
                            texts = @"系统排空";
                            break;
                        case 15:
                            texts = @"系统建压检测";
                            break;
                        case 16:
                            texts = @"系统剂量喷射";
                            break;
                        default:
                            texts = @"未知状态";
                            break;
                    }
                    
                    break;
                }
                case 8:
                case 9:
                {
                    double number = ((bytes[0] << 8) + bytes[1]) * 0.1;
                    
                    texts = [NSString stringWithFormat:@"%.2f g", number];
                    
                    break;
                }
            }
            
            [self.contentValuesArray replaceObjectAtIndex:i withObject:texts];
            
            dispatch_sync(dispatch_get_main_queue(),
                          ^{
                              UITableViewCell *tableViewCell = [self.contentTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataIndex inSection:0]];
                              UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)tableViewCell.accessoryView;
                              tableViewCell.detailTextLabel.text = texts;
                              [activityIndicatorView stopAnimating];
                              activityIndicatorView.hidden = YES;
                          });
        }
        
        ++counter;
        
        if (counter > 239)
        {
            error = RoutineControlTimeout;
            goto theEnd;
        }
        
        sleep(1);
    }
    
theEnd:
    
    //结束时停止服务标识为0x0312的例程控制.
    [self.businessLayer stopRoutineControlByIdentifier:0x0322];
    
    
    dispatch_sync(dispatch_get_main_queue(),
                  ^{
                      if (error != Success)
                      {
                          [SVProgressHUD showErrorWithStatus:[self.businessLayer getErrorMessage:error]];
                      }
                      else
                      {
                          [SVProgressHUD showSuccessWithStatus:@"后处理测试完成."];
                      }
                      
                      self.dataIndex = -1;
                      self.isNowWorking = NO;
                      
                      [self.contentTableView reloadData];
                      
                      self.navigationItem.leftBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.title = @"测试";
                  });
    
    return;
}

@end
