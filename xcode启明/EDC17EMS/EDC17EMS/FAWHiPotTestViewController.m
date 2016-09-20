//
//  FAWHiPotTestViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-7.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWHiPotTestViewController.h"

@interface FAWHiPotTestViewController ()

@end

@implementation FAWHiPotTestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.contentTextsArray = [NSMutableArray arrayWithObjects:@"轨压上升时间1", @"轨压上升时间2", @"轨压上升时间3", @"轨压上升时间4", @"轨压下降时间1", @"轨压下降时间2", nil];
        
        self.businessLayer = ((FAWAppDelegate *)([[UIApplication sharedApplication] delegate])).businessLayer;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.contentValuesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.contentTextsArray count];  ++i)
    {
        [self.contentValuesArray addObject:@"等待测试"];
    }
    
    [self.contentTableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"高压测试";
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

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)asyncWorkStarted
{
    Error error = Success;
    //开启压缩测试例程附加数据, 长度29字节, 填充0x00.
    Byte extraBytes[29] = {0x00};
    
    NSData * extraData = nil;
    
    //测试结果检索地址, 每行一个相对地址.
    Byte resultAddressesBytes[][3] =
    {
        {0x50, 0x10, 0x1a},         //上升时间1
        {0x50, 0x10, 0x1c},         //上升时间2
        {0x50, 0x10, 0x1e},         //上升时间3
        {0x50, 0x10, 0x20},         //上升时间4
        {0x50, 0x10, 0x12},         //下降时间1
        {0x50, 0x10, 0x14}          //下降时间2
    };
    
    NSUInteger specialError = 0;
    
    NSData * data = nil;
    Byte * bytes = nil;
    double number = 0;
    
    //判定用户是否取消测试的标志, 以下同解.
    if (!self.isNowWorking)
    {
        error = Canceled;
        goto theEnd;
    }
    
    error = [self.businessLayer prepareOperation];
    
    if (!self.isNowWorking)
    {
        error =Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    error = [self.businessLayer changeSessionMode:0x40];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    error = [self.businessLayer passAccessLimit];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    error = [self.businessLayer readData:&data byIdentifier:0x0162];
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    bytes = (Byte *)[data bytes];
    
    number = ((bytes[0] << 8) + bytes[1]) * 0.1 - 273.14;
    
    if (number < 60)
    {
        error = RoutineControlFailure;
        goto theEnd;
    }
    
    //压缩测试例程控制服务码0x31, 参数(启动例程)0x01, 服务标识0x0314(Big Endian), 附加数据29字节, 填充0x00.
    //开启压缩测试例程.
    extraData = [NSData dataWithBytes:extraBytes length:sizeof(extraBytes)];
    error = [self.businessLayer startRoutineControlByIdentifier:0x0314 withData:extraData];
    
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

        //判断高压测试运行条件状态.
        Byte * bytes = (Byte *)[data bytes];
        specialError = (bytes[0] << 8) + bytes[1];
        error = RoutineControlException;
        goto theEnd;
    }
    
    //启动循环检查测试结果, 计数器总数300, 每轮循环暂停1秒, 总计5分钟.
    NSInteger counter = 0;
    
    while (YES)
    {
        //读取动态数据: 高压测试状态, 服务标识0x01dc(Big Endian), 返回值为0x0c时表示测试结束, 否则继续检测其他标识.
        NSData * readData = nil;
        error = [self.businessLayer readData:&readData byIdentifier:0x01dc];
        
        if (!self.isNowWorking)
        {
            error  = Canceled;
            goto theEnd;
        }
        
        if (error != Success && error != NegativeResponse)
        {
            goto theEnd;
        }
        
        if (error == Success)
        {
            Byte * readBytes = (Byte *)[readData bytes];
            
            //读取结果等于0x0c表示测试结束, 跳出循环读取测试结果完成测试.
            if (readBytes[0] == 0x0c)
            {
                break;
            }
        }
        else
        {
            //累计循环计数器, 直到300.
            ++counter;
            
            //超时间隔2分钟, 循环计数器不得大于119, 即120秒.
            if (counter > 119)
            {
                error = RoutineControlTimeout;
                goto theEnd;
            }
            
            sleep(1);
            
            continue;
        }
        
        //继续读取动态数据: 高压测试运行条件状态, 服务标识0x01d7, 返回值不为0x00表示检测结束, 为0x00表示检测仍需继续进行.
        error = [self.businessLayer readData:&readData byIdentifier:0x01d7];
        
        if (!self.isNowWorking)
        {
            error = Canceled;
            goto theEnd;
        }
        
        //若网络连接中断、超时或其他错误则退出.
        if (error != Success && error != NegativeResponse)
        {
            goto theEnd;
        }
        
        //若读取数据成功
        if (error == Success)
        {
            //判断高压测试运行条件状态.
            Byte * readBytes = (Byte *)[readData bytes];
            specialError = (readBytes[0] << 8) + readBytes[1];
            error = RoutineControlException;
            goto theEnd;
        }
        
        //累计循环计数器, 直到300.
        ++counter;
        
        //超时间隔2分钟, 循环计数器不得大于119, 即120秒.
        if (counter > 119)
        {
            error = RoutineControlTimeout;
            goto theEnd;
        }
    }
    
    //读取测试结果数据, 共6个.
    for (int i = 0; i < sizeof(resultAddressesBytes) / sizeof(resultAddressesBytes[0]); ++i)
    {
        NSData * addressData = [NSData dataWithBytes:resultAddressesBytes[i] length:sizeof(resultAddressesBytes[i])];
        
        NSData * resultData = nil;
        
        //每组数据长度均为2字节.
        error = [self.businessLayer readData:&resultData byAddress:addressData andLength:0x02];
        
        if (!self.isNowWorking)
        {
            error = Canceled;
        }
        
        if (error != Success)
        {
            goto theEnd;
        }
        
        Byte * resultBytes = (Byte *)[resultData bytes];
        
        //此处为Little Endian编码, 计算因子为10, 即取得的数要乘以10为实际值.
        double resultNumber = (*(short *)resultBytes) * 10;
        
        NSString * resultText = [NSString stringWithFormat:@"%.2f ms", resultNumber];
        
        [self.contentValuesArray replaceObjectAtIndex:i withObject:resultText];
    }
    
    error = Success;
    
theEnd:
    
    //结束时停止服务标识为0x0314的例程控制.
    [self.businessLayer stopRoutineControlByIdentifier:0x0314];
    
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
                                  [errorMessage appendString:@"轨压处于非闭环控制状态.\n"];
                              }
                              
                              if (specialError & 64)
                              {
                                  [errorMessage appendString:@"发动机处于非怠速状态.\n"];
                              }
                              
                              if (specialError & 128)
                              {
                                  [errorMessage appendString:@"发动机水温过低.\n"];
                              }
                              
                              if (specialError & 512)
                              {
                                  [errorMessage appendString:@"测试中喷油量异常.\n"];
                              }
                              
                              if (specialError & 1024)
                              {
                                  [errorMessage appendString:@"测试中转速异常.\n"];
                              }
                              
                              if (specialError & 2048)
                              {
                                  [errorMessage appendString:@"测试中轨压波动(偏小).\n"];
                              }
                              
                              if (specialError & 4096)
                              {
                                  [errorMessage appendString:@"测试中轨压波动(偏大).\n"];
                              }
                              
                              [SVProgressHUD showErrorWithStatus:errorMessage];
                          }
                      }
                      else
                      {
                          [SVProgressHUD showSuccessWithStatus:@"高压测试完成."];
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
