//
//  FAWRunUpTestViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-5.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWRunUpTestViewController.h"

@interface FAWRunUpTestViewController ()

@end

@implementation FAWRunUpTestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.contentTextsArray = [NSMutableArray arrayWithObjects:@"第1缸转速", @"第2缸转速", @"第3缸转速", @"第4缸转速", @"第5缸转速", @"第6缸转速", nil];
        
        self.businessLayer = ((FAWAppDelegate *)([[UIApplication sharedApplication] delegate])).businessLayer;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.contentValuesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.contentTextsArray count]; ++i)
    {
        [self.contentValuesArray addObject:@"等待测试"];
    }
    
    [self.contentTableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"加速测试";
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
    
    if (!tableViewCell)
    {
        tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ContentTableViewCell"];
    }
    
    tableViewCell.textLabel.text = [self.contentTextsArray objectAtIndex:indexPath.row];
    tableViewCell.detailTextLabel.text = [self.contentValuesArray objectAtIndex:indexPath.row];
    
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
        
        [SVProgressHUD showWithStatus:@"正在测试, 请稍后..."];
        
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
    
    NSData * waterTemperatureData = nil;
    Byte * waterTemperatureBytes = nil;
    double waterTemperature = 0;
    
    //气缸测试参数及测试顺序, 见下文使用.
    Byte cylinderOrder[] = {0xff, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05};
    
    //转速测试结果保存数组, 丢掉第1组数据, 只保留第2-7组
    double resultSpeed[6]= {0};
    
    NSUInteger specialError = 0;
    
    //判定用户是否取消测试的标志, 以下同解.
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
    
    //变更会话模式到0x40模式(目前不知道0x40是何模式).
    error = [self.businessLayer changeSessionMode:0x40];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    //加速测试需要安全访问认证.
    error = [self.businessLayer passAccessLimit];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    //加速测试需要满足水温大于60摄氏度条件, 读取水温使用服务标识0x0162.
    error = [self.businessLayer readData:&waterTemperatureData byIdentifier:0x0162];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    waterTemperatureBytes = (Byte *)[waterTemperatureData bytes];
    
    //水温返回2字节Big Endian整数, 实际结果需经过换算, 换算因子0.1, 偏移量-273.14.
    waterTemperature = ((waterTemperatureBytes[0] << 8) + waterTemperatureBytes[1]) * 0.1 - 273.14;
    
    //测试要求水温必须大于60摄氏度.
    if (waterTemperature <= 60)
    {
        error = RoutineControlFailure;
        goto theEnd;
    }
    
    //加速测试共测试6缸, 另加1次全缸测试供内部使用, 共7次测试.
    for (int i = 0; i < 7; ++i)
    {
        //例程参数格式: {0x00, 气缸序号, 34字节0x00}, 共36字节.
        Byte extraBytes[36] = {0x00};
        extraBytes[1] = cylinderOrder[i];
        
        NSData * extraData = [NSData dataWithBytes:extraBytes length:sizeof(extraBytes)];
        
        //加速测试例程标识为0x0316.
        error = [self.businessLayer startRoutineControlByIdentifier:0x0316 withData:extraData];
        
        if (!self.isNowWorking)
        {
            error =Canceled;
        }
        
        if (error != Success && error != NegativeResponse)
        {
            goto theEnd;
        }
        
        if (error == NegativeResponse)
        {
            NSData * data = nil;
            error = [self.businessLayer readData:&data byIdentifier:0x01de];
            
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
            
            //判断高压测试运行条件状态.
            Byte * bytes = (Byte *)[data bytes];
            specialError = (bytes[0] << 8) + bytes[1];
            error = RoutineControlException;
            goto theEnd;
        }
        
        while (YES)
        {
            //轮询例程控制状态.
            error = [self.businessLayer getRoutineControlStatusByIdentifier:0x0316];
            
            if (!self.isNowWorking)
            {
                error = Canceled;
                goto theEnd;
            }
            
            //例程状态显示执行城成功, 跳出循环读取转速值.
            if (error == Success)
            {
                break;
            }
            
            //RoutineControlUnknown表示例程控制出现其他情况但错误仅限于例程控制.
            //当发生其他非例程控制内错误时, 跳出循环, 提示出错.
            if (error != RoutineControlFailure)
            {
                goto theEnd;
            }

            //检测终止标志.
            NSData * stopFlagData = nil;
            error = [self.businessLayer readData:&stopFlagData byIdentifier:0x01de];
            
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
                error = RoutineControlTimeout;
                goto theEnd;
            }
            
            //检测终止标志2字节, Big Endian表示.
            Byte * stopFlagBytes = (Byte *)[stopFlagData bytes];
            
            ushort stopFlag = (stopFlagBytes[0] << 8) + stopFlagBytes[1];
            
            if (stopFlag)
            {
                error = RoutineControlFailure;
                goto theEnd;
            }
        }
        
        //当轮询第一组数(i等于0), 即气缸序号为0xff时, 不读取数值, 不保存数值, 直接进行下一组数据读取.
        if (i == 0)
        {
            continue;
        }
        
        //此处开始读取转速值.
        NSData * speedData = nil;
        
        error = [self.businessLayer readData:&speedData byIdentifier:0x01e2];
        
        if (!self.isNowWorking)
        {
            error = Canceled;
            goto theEnd;
        }
        
        //单次读取转速失败后, 例程不终止, 继续进行下轮循环.
        if (error != Success)
        {
            //标记转速为-1代表该轮读取数据失败.
            resultSpeed[i - 1] = -1;
            continue;
        }
        
        Byte * speedBytes = (Byte *)[speedData bytes];
        
        double speed = ((speedBytes[0] << 8) + speedBytes[1]) * 0.5;
        
        //由于第一组数据忽略, resultSpeed内存储向后移动1个元素.
        resultSpeed[i - 1] = speed;
    }
    
    //将转速转换为文本存储至数据源, 缸序号与缸实际对应顺序如下:
    
    //序号    缸   结果索引
    //0x00  第1缸     0
    //0x01  第5缸     1
    //0x02  第3缸     2
    //0x03  第6缸     3
    //0x04  第2缸     4
    //0x05  第4缸     5
    
    //以下代码转换缸序号与顺序:
    
    //第1缸
    if (resultSpeed[0] == -1)
    {
        [self.contentValuesArray replaceObjectAtIndex:0 withObject:@"测试失败"];
    }
    else
    {
        [self.contentValuesArray replaceObjectAtIndex:0 withObject:[NSString stringWithFormat:@"%.2f rpm", resultSpeed[0]]];
    }
    
    //第2缸
    if (resultSpeed[4] == -1)
    {
        [self.contentValuesArray replaceObjectAtIndex:1 withObject:@"测试失败"];
    }
    else
    {
        [self.contentValuesArray replaceObjectAtIndex:1 withObject:[NSString stringWithFormat:@"%.2f rpm", resultSpeed[4]]];
    }
    
    //第3缸
    if (resultSpeed[2] == -1)
    {
        [self.contentValuesArray replaceObjectAtIndex:2 withObject:@"测试失败"];
    }
    else
    {
        [self.contentValuesArray replaceObjectAtIndex:2 withObject:[NSString stringWithFormat:@"%.2f rpm", resultSpeed[2]]];
    }
    
    //第4缸
    if (resultSpeed[5] == -1)
    {
        [self.contentValuesArray replaceObjectAtIndex:3 withObject:@"测试失败"];
    }
    else
    {
        [self.contentValuesArray replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"%.2f rpm", resultSpeed[5]]];
    }
    
    //第5缸
    if (resultSpeed[1] == -1)
    {
        [self.contentValuesArray replaceObjectAtIndex:4 withObject:@"测试失败"];
    }
    else
    {
        [self.contentValuesArray replaceObjectAtIndex:4 withObject:[NSString stringWithFormat:@"%.2f rpm", resultSpeed[1]]];
    }
    
    //第6缸
    if (resultSpeed[3] == -1)
    {
        [self.contentValuesArray replaceObjectAtIndex:5 withObject:@"测试失败"];
    }
    else
    {
        [self.contentValuesArray replaceObjectAtIndex:5 withObject:[NSString stringWithFormat:@"%.2f rpm", resultSpeed[3]]];
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
                                  [errorMessage appendString:@"油门踏板被踩下.\n"];
                              }
                              
                              if (specialError & 32)
                              {
                                  [errorMessage appendString:@"测试运行超时.\n"];
                              }
                              
                              if (specialError & 64)
                              {
                                  [errorMessage appendString:@"测试参数错误.\n"];
                              }
                              
                              if (specialError & 256)
                              {
                                  [errorMessage appendString:@"发动机水温过低.\n"];
                              }
                              
                              if (specialError & 512)
                              {
                                  [errorMessage appendString:@"测试中同步信号异常.\n"];
                              }
                              
                              [SVProgressHUD showErrorWithStatus:errorMessage];
                          }
                      }
                      else
                      {
                          [SVProgressHUD showSuccessWithStatus:@"加速测试完成."];
                      }
                      
                      self.isNowWorking = NO;
                      
                      [self.contentTableView reloadData];
                      
                      self.navigationItem.leftBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.title = @"测试";
                  });
    
    return;
}

@end
