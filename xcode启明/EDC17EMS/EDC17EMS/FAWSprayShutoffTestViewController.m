//
//  FAWSprayShutoffTestViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-17.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#include "SVProgressHUD.h"
#import "FAWSprayShutoffTestViewController.h"

@interface FAWSprayShutoffTestViewController ()

@end

@implementation FAWSprayShutoffTestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.contentSectionsArray = [NSMutableArray arrayWithObjects:@"第1缸", @"第2缸", @"第3缸", @"第4缸", @"第5缸", @"第6缸", nil];
        
        self.businessLayer = ((FAWAppDelegate *)([[UIApplication sharedApplication] delegate])).businessLayer;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.contentValuesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.contentSectionsArray count]; ++i)
    {
        NSNumber * number = [NSNumber numberWithInteger:0];
        [self.contentValuesArray addObject:number];
    }
    
    [self.contentTableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"断缸测试";
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
    return [self.contentSectionsArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * tableViewCell = [self.contentTableView dequeueReusableCellWithIdentifier:@"ContentTableViewCell"];
    
    if (!tableViewCell)
    {
        tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ContentTableViewCell"];
        
        UISegmentedControl * segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"无操作", @"断缸", @"预喷", nil]];
        
        segmentedControl.tag = indexPath.section;
        segmentedControl.frame = tableViewCell.bounds;
        [segmentedControl addTarget:self action:@selector(choiseSegmentedControlVAlueChanged:) forControlEvents:UIControlEventValueChanged];
        
        [tableViewCell.contentView addSubview:segmentedControl];
    }
    
    for (id item in tableViewCell.contentView.subviews)
    {
        if ([item isKindOfClass:[UISegmentedControl class]])
        {
            UISegmentedControl * segmentedControl = (UISegmentedControl *)item;
            segmentedControl.selectedSegmentIndex = [[self.contentValuesArray objectAtIndex:indexPath.section] integerValue];
        }
    }
    
    return tableViewCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.contentSectionsArray objectAtIndex:section];
}

- (void)actButtonPressed:(id)sender
{
    if (!self.isNowWorking)
    {
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.title = @"停止";
        
        self.contentTableView.userInteractionEnabled = NO;
        
        self.isNowWorking = YES;
        
        [SVProgressHUD showWithStatus:@"正在测试, 请稍后..."];
        
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

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)choiseSegmentedControlVAlueChanged:(id)sender
{
    UISegmentedControl * segmentedControl = (UISegmentedControl *)sender;
    
    NSNumber * number = [NSNumber numberWithInteger:segmentedControl.selectedSegmentIndex];
    
    [self.contentValuesArray replaceObjectAtIndex:segmentedControl.tag withObject:number];
}

- (void)asyncWorkStarted
{
    Error error = Success;
    
    //断缸测试例程参数: {0x00, 第1缸, 第2缸, 第3缸, 第4缸, 第5缸, 第6缸}, 共7个字节.
    Byte extraBytes[7] = {0};
    NSData * extraData = nil;
    
    //例程超时计时器, 超时时间15秒.
    NSInteger counter = 0;

    NSUInteger specialError = 0;
    
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
    
    //会话模式标识0x40, 目前未知是何模式.
    error = [self.businessLayer changeSessionMode:0x40];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    //断缸测试需要认证安全访问序列.
    error = [self.businessLayer passAccessLimit];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    //断缸测试参数顺序与实际缸顺序如下所示:
    
    //参数索引      缸序号(或填充字节)
    //  0           填充(0x00)
    //  1               1
    //  2               5
    //  3               3
    //  4               6
    //  5               2
    //  6               4
    
    //下面代码读取用户选择并将映射转换为指令标识码, 实际缸序号为用户界面索引加1.
    extraBytes[1] = (Byte)[[self.contentValuesArray objectAtIndex:0] integerValue];
    extraBytes[2] = (Byte)[[self.contentValuesArray objectAtIndex:4] integerValue];
    extraBytes[3] = (Byte)[[self.contentValuesArray objectAtIndex:2] integerValue];
    extraBytes[4] = (Byte)[[self.contentValuesArray objectAtIndex:5] integerValue];
    extraBytes[5] = (Byte)[[self.contentValuesArray objectAtIndex:1] integerValue];
    extraBytes[6] = (Byte)[[self.contentValuesArray objectAtIndex:3] integerValue];
    
    //用户选择索引对应断缸参数映射:
    
    //用户选择索引    断缸参数
    //  0(无操作)      0x18
    //  1(断缸)       0x00
    //  2(预喷)       0x08
    
    //下面代码将用户选择索引映射为断缸参数, 参数0为填充, 无需操作.
    for (int i = 1;  i< 7; ++i)
    {
        if (extraBytes[i] == 0)
        {
            extraBytes[i] = 0x18;
        }
        else if (extraBytes[i] == 1)
        {
            extraBytes[i] = 0x00;
        }
        else if (extraBytes[i] == 2)
        {
            extraBytes[i] = 0x08;
        }
        else
        {
            error = RoutineControlFailure;
            goto theEnd;
        }
    }
    
    extraData = [NSData dataWithBytes:extraBytes length:sizeof(extraBytes)];
    
    //开始断缸例程, 断缸例程服务标识为0x0315.
    error = [self.businessLayer startRoutineControlByIdentifier:0x0315 withData:extraData];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success && error != NegativeResponse)
    {
        goto theEnd;
    }
    
    if (error == NegativeResponse)
    {
        NSData * data = nil;
        error = [self.businessLayer readData:&data byIdentifier:0x01d7];
        
        if (!self.isNowWorking)
        {
            error = Canceled;
            goto theEnd;
        }
        
        //若网络连接中断、超时或其他错误则退出.
        if (error != Success)
        {
            error = RoutineControlTimeout;
            goto theEnd;
        }

        Byte * bytes = (Byte *)[data bytes];
        specialError = (bytes[0] << 8);
        error = RoutineControlException;
        goto theEnd;
    }
    
    while (YES)
    {
        //断缸测试需要实时读取发动机转速, 并且保证转速大于0(即发动机处于启动状态).
        NSData * engineSpeedData = nil;
        
        error = [self.businessLayer readData:&engineSpeedData byIdentifier:0x015e];
        
        if (!self.isNowWorking)
        {
            error = Canceled;
        }
        
        if (error != Success)
        {
            goto theEnd;
        }
        
        Byte * engineSpeedBytes = (Byte *)[engineSpeedData bytes];
        
        //发动机转速系数因子为0.5, 数据长度2字节.
        double engineSpeed = ((engineSpeedBytes[0] << 8) + engineSpeedBytes[1]) * 0.5;
        
        if (engineSpeed <= 0)
        {
            error = RoutineControlFailure;
            goto theEnd;
        }
        
        ++counter;
        
        //超时计时器, 超时时间15秒.
        if (counter > 14)
        {
            error = RoutineControlTimeout;
            goto theEnd;
        }
        
        sleep(1);
    }
    
    error = Success;
    
theEnd:
    
    //结束时停止服务标识为0x0316的例程控制.
    [self.businessLayer stopRoutineControlByIdentifier:0x0316];
    
    dispatch_sync(dispatch_get_main_queue(),
                  ^{
                      if (error != Success)
                      {
                          if (error != RoutineControlException)
                          {
                              [SVProgressHUD showErrorWithStatus:[self.businessLayer getErrorMessage:error]];
                          }
                          else
                          {
                              NSMutableString * errorMessage = [[NSMutableString alloc] init];
                              
                              if (specialError & 1)
                              {
                                  [errorMessage appendString:@"系统故障存在.\n"];
                              }
                              
                              if (specialError & 2)
                              {
                                  [errorMessage appendString:@"离合器信号异常.\n"];
                              }
                              
                              if (specialError & 4)
                              {
                                  [errorMessage appendString:@"车速不为0.\n"];
                              }
                              
                              if (specialError & 8)
                              {
                                  [errorMessage appendString:@"刹车信号不为0.\n"];
                              }
                              
                              if (specialError & 16)
                              {
                                  [errorMessage appendString:@"发动机转速过低.\n"];
                              }
                              
                              [SVProgressHUD showErrorWithStatus:errorMessage];
                          }
                      }
                      else
                      {
                          [SVProgressHUD showSuccessWithStatus:@"断缸测试完成."];
                      }
                      
                      self.isNowWorking = NO;
                      
                      self.contentTableView.userInteractionEnabled = YES;
                      self.navigationItem.leftBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.title = @"测试";
                  });
    
    return;

}

@end
