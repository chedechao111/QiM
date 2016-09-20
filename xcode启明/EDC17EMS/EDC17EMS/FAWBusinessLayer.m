//
//  FAWBusinessLayer.m
//  EDC17EMS
//
//  Created by Zephyr on 2015-6-15.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "FAWBusinessLayer.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/ioctl.h>

#define SERVER_ADDRESS ("192.168.1.10")
#define SERVER_PORT (6954)
#define SEND_RECV_TIME_OUT (5)
#define CONNECT_TIME_OUT (5)

#define COMMON_BUFFER_LENGTH (4096)

#define SEND_PACKAGE_HEAD (0xaa)
#define SEND_PACKAGE_TAIL (0x55)

#define RECV_PACKAGE_HEAD SEND_PACKAGE_TAIL
#define RECV_PACKAGE_TAIL SEND_PACKAGE_HEAD

#define AUTHENTICATION_REQUEST_BYTES 0xaa, 0x00, 0x03, 0x03, 0x01, 0x03, 0x55
#define AUTHENTICATION_EXPECT_BYTES 0x55, 0x00, 0x03, 0x03, 0x01, 0xf1, 0xaa
#define TRANSMISSION_FAILURE_BYTES 0x55, 0x00, 0x03, 0x03, 0x08, 0xf1, 0xaa
#define NO_RESPONSE_BYTES 0x55, 0x00, 0x03, 0x03, 0x08, 0xf2, 0xaa

#define READ_DATA_REQUEST_IDENTIFIER (0x22)
#define READ_DATA_RESPONSE_IDENTIFIER (0x62)
#define READ_DATA_REQUEST_LENGTH (3)

#define READ_OBD_DATA_REQUEST_IDENTIFIER (0x01)
#define READ_OBD_DATA_RESPONSE_IDENTIFIER (0x41)
#define READ_OBD_DATA_REQUEST_LENGTH (2)

#define CHANGE_SESSION_MODE_REQUEST_IDENTIFIER (0x10)
#define CHANGE_SESSION_MODE_RESPONSE_IDENTIFIER (0x50)
#define CHANGE_SESSION_MODE_REQUEST_LENGTH (2)

#define PASS_ACCESS_LIMIT_REQUEST_IDENTIFIER (0x27)
#define PASS_ACCESS_LIMIT_RESPONSE_IDENTIFIER (0x67)
#define PASS_ACCESS_LIMIT_PARAMETER_SEED (0x01)
#define PASS_ACCESS_LIMIT_PARAMETER_KEY (0X02)
#define PASS_ACCESS_LIMIT_SEED_LENGTH (4)
#define PASS_ACCESS_LIMIT_KEY_LENGTH (4)
#define PASS_ACCESS_LIMIT_KEY_REQUEST_LENGTH (6)

#define CONTROL_IO_REQUEST_IDENTIFIER (0x2f)
#define CONTROL_IO_RESPONSE_IDENTIFIER (0x6f)
#define CONTROL_IO_PARAMETER_START (0x03)
#define CONTROL_IO_PARAMETER_STOP (0x00)
#define CONTROL_IO_CODE_LENGTH (2)
#define CONTROL_IO_SUCCESS (0x01)
#define CONTROL_IO_FAILURE (0x02)
#define CONTROL_IO_START_REQUEST_LENGTH (6)
#define CONTROL_IO_STOP_REQUEST_LENGTH (4)

#define CONTROL_ROUTINE_REQUEST_IDENTIFIER (0x31)
#define CONTROL_ROUTINE_RESPONSE_IDENTIFIER (0x71)
#define CONTROL_ROUTINE_PARAMETER_START (0x01)
#define CONTROL_ROUTINE_PARAMETER_STOP (0x02)
#define CONTROL_ROUTINE_PARAMETER_STATUS (0x03)
#define CONTROL_ROUTINE_SUCCESS (0x00)
#define CONTROL_ROUTINE_FAILURE (0x01)
#define CONTROL_ROUTINE_REQUEST_PREFIX_LENGTH (4)

#define READ_DTCS_REQUEST_IDENTIFIER (0x19)
#define READ_DTCS_RESPONSE_IDENTIFIER (0x59)
#define READ_DTCS_PARAMETER (0x02)
#define READ_DTCS_MASK_CURRENT (0x01)
#define READ_DTCS_MASK_CONFIRMED (0x08)
#define READ_DTCS_EFFECTIVE_CODE_LENGTH (3)
#define READ_DTCS_FULL_CODE_LENGTH (4)

#define READ_FROZEN_FRAMES_REQUEST_IDENTIFIER (0x19)
#define READ_FROZEN_FRAMES_RESPONSE_IDENTIFIER (0x59)
#define READ_FROZEN_FRAMES_PARAMETER (0x04)
#define READ_FROZEN_FRAMES_MASK (0xff)
#define READ_FROZEN_FRAMES_REQUEST_LENGTH (6)

#define CLEAR_DTCS_REQUEST_LENGTH (4)
#define CLEAR_DTCS_REQUEST_IDENTIFIER (0x14)
#define CLEAR_DTCS_RESPONSE_IDENTIFIER (0x54)
#define CLEAR_DTCS_PARAMETER_1 (0xff)
#define CLEAR_DTCS_PARAMETER_2 (0xff)
#define CLEAR_DTCS_PARAMETER_3 (0Xff)

@implementation FAWBusinessLayer

//构造函数
- (id)init
{
    self = [super init];
    
    if (self)
    {
        mySocket = -1;
    }
    
    return self;
}

//初始化Socket
- (Error)resetSocket
{
    mySocket = socket(AF_INET, SOCK_STREAM, 0);
    
    if (mySocket == -1)
    {
        return InnerError;
    }
    
    struct timeval timeout;
    
    timeout.tv_sec = SEND_RECV_TIME_OUT;
    timeout.tv_usec = 0;

    int status = setsockopt(mySocket, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
    
    if (status == -1)
    {
        close(mySocket);
        
        return InnerError;
    }
    
    timeout.tv_sec = SEND_RECV_TIME_OUT;
    timeout.tv_usec = 0;
    
    status = setsockopt(mySocket, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    
    if (status == -1)
    {
        close(mySocket);
        
        return InnerError;
    }
    
    return Success;
}

//重置业务层
- (Error)prepareOperation
{
    Error error = Success;
    
    error = [self disconnectFromServer];
    
    if (error != Success)
    {
        return error;
    }
    
    error = [self resetSocket];
    
    if (error != Success)
    {
        return error;
    }
    
    error = [self connectToServer];
    
    if (error != Success)
    {
        return error;
    }
    
    error = [self authenticateIdentity];
    
    return error;
}

//连接到ECU
- (Error)connectToServer
{
    if (mySocket == -1)
    {
        return InnerError;
    }
    
    struct sockaddr_in serverEndPoint;
    memset(&serverEndPoint, 0, sizeof(serverEndPoint));
    
    serverEndPoint.sin_len = sizeof(serverEndPoint);
    serverEndPoint.sin_family = AF_INET;
    serverEndPoint.sin_addr.s_addr = inet_addr(SERVER_ADDRESS);
    serverEndPoint.sin_port = htons(SERVER_PORT);
    
    int option = 1;
    if (ioctl(mySocket, FIONBIO, &option) < 0)
    {
        return InnerError;
    }
    
    int status = connect(mySocket, (struct sockaddr *)&serverEndPoint, sizeof(serverEndPoint));
    
    if (status == -1)
    {
        if (errno == EINPROGRESS)
        {
            struct timeval timeout;
            timeout.tv_sec = CONNECT_TIME_OUT;
            timeout.tv_usec = 0;
            
            fd_set set;
            FD_ZERO(&set);
            FD_SET(mySocket, &set);
            
            int error = -1;
            int errorLength = sizeof(error);
            
            if (select(mySocket + 1, nil, &set, nil, &timeout) > 0)
            {
                getsockopt(mySocket, SOL_SOCKET, SO_ERROR, &error, (socklen_t *)&errorLength);
                
                if (error != 0)
                {
                    return Timeout;
                }
            }
            else
            {
                return Timeout;
            }
            
        }
        else
        {
            return Timeout;
        }
    }
    
    option = 0;
    
    if (ioctl(mySocket, FIONBIO, &option) < 0)
    {
        return InnerError;
    }
    
    return Success;
}

//从ECU断开
- (Error)disconnectFromServer
{
    if (mySocket == -1)
    {
        return Success;
    }
    
    shutdown(mySocket, SHUT_RDWR);
    
    close(mySocket);
    
    return Success;
}

//身份认证(内部协议)
- (Error)authenticateIdentity
{
    if (mySocket == -1)
    {
        return InnerError;
    }
    
    Byte authenticationRequestBytes[] = {AUTHENTICATION_REQUEST_BYTES};
    Byte authenticationExpectBytes[] = {AUTHENTICATION_EXPECT_BYTES};
    
    long status = send(mySocket, authenticationRequestBytes, sizeof(authenticationRequestBytes), 0);
    
    if (status != sizeof(authenticationRequestBytes))
    {
        return Timeout;
    }
    
    Byte authenticationResponseBytes[COMMON_BUFFER_LENGTH] = {0};
    
    status = recv(mySocket, authenticationResponseBytes, sizeof(authenticationResponseBytes), 0);

    if (status != sizeof(authenticationExpectBytes))
    {
        return Timeout;
    }
    
    if (memcmp(authenticationExpectBytes, authenticationResponseBytes, sizeof(authenticationExpectBytes)))
    {
        return AuthenticationFailure;
    }
    
    return Success;
}

//发动数据
- (Error)sendData:(NSData *)data
{
    if (!data)
    {
        return InvalidParameter;
    }
    
    if ([data length] == 0)
    {
        return InvalidParameter;
    }
    
    if (mySocket == -1)
    {
        return InnerError;
    }
    
    NSData * tempData = nil;
    
    if (![self escapeInputData:data toOutputData:&tempData])
    {
        return InvalidProtocol;
    }
        
    long status = send(mySocket, [tempData bytes], [tempData length], 0);
    
    if (status != [tempData length])
    {
        return Timeout;
    }
    
    return Success;
}

//接收数据
- (Error)receiveData:(NSData **)data
{
    if (!data)
    {
        return InvalidParameter;
    }
    
    if (mySocket == -1)
    {
        return InnerError;
    }
    
    while (TRUE)
    {
        Byte commonResponseBytes[COMMON_BUFFER_LENGTH] = {0};
        
        long status = recv(mySocket, commonResponseBytes, sizeof(commonResponseBytes), 0);
        
        if (status == -1)
        {
            return Timeout;
        }
        
        if (commonResponseBytes[0] != RECV_PACKAGE_HEAD || commonResponseBytes[status - 1] != RECV_PACKAGE_TAIL)
        {
            return InvalidProtocol;
        }
        
        Byte transmissionFailureBytes[] = {TRANSMISSION_FAILURE_BYTES};
        Byte noResponseBytes[] = {NO_RESPONSE_BYTES};
        
        if (status == sizeof(transmissionFailureBytes))
        {
            if (!memcmp(commonResponseBytes, transmissionFailureBytes, status))
            {
                return TransmissionFailure;
            }
        }
        
        if (status == sizeof(noResponseBytes))
        {
            if (!memcmp(commonResponseBytes, noResponseBytes, status))
            {
                return NoResponse;
            }
        }
        
        NSData * tempData = nil;
        
        tempData = [NSData dataWithBytes:commonResponseBytes length:status];
        
        if (![self unescapeInputData:tempData toOutputData:data])
        {
            return InvalidProtocol;
        }
        
        Byte * bytes = (Byte *)[(*data) bytes];
        
        if (bytes[0] == 0x7f && bytes[2] == 0x78)
        {
            continue;
        }
        
        break;
    }
    
    return Success;
}

//更改会话模式
- (Error)changeSessionMode:(NSInteger)sessionId
{
    Error error = Success;
    
    if (mySocket == -1)
    {
        return InnerError;
    }
    
    Byte changeSessionModeRequestBytes[CHANGE_SESSION_MODE_REQUEST_LENGTH] = {0};
    changeSessionModeRequestBytes[0] = 0x10;
    changeSessionModeRequestBytes[1] = (Byte)sessionId;
    
    NSData * data = [NSData dataWithBytes:changeSessionModeRequestBytes length:sizeof(changeSessionModeRequestBytes)];
    
    error = [self sendData:data];
    
    if (error != Success)
    {
        return error;
    }

    error = [self receiveData:&data];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte * bytes = (Byte *)[data bytes];
    
    if (bytes[0] != 0x50 || bytes[1] != (Byte)sessionId)
    {
        return NegativeResponse;
    }
    
    return Success;
}

//ECU访问认证
- (Error)passAccessLimit
{
    Error error = Success;
    
    if (mySocket == -1)
    {
        return InnerError;
    }
    
    Byte requestSeedRequestBytes[] = {0x27, 0x09};
    
    NSData * data = [NSData dataWithBytes:requestSeedRequestBytes length:sizeof(requestSeedRequestBytes)];
    
    error = [self sendData:data];
    
    if (error != Success)
    {
        return error;
    }
    
    error = [self receiveData:&data];
    
    if (error != Success)
    {
        return error;
    }

    Byte * bytes = (Byte *)[data bytes];
    
    if (bytes[0] != 0x67 || bytes[1] != 0x09)
    {
        return NegativeResponse;
    }
    
    data = [NSData dataWithBytes:bytes + 2 length:PASS_ACCESS_LIMIT_SEED_LENGTH];
    
    if (![self fromSeed:data toKey:&data])
    {
        return InnerError;
    }
    
    Byte authenticateKeyRequestBytes[PASS_ACCESS_LIMIT_KEY_REQUEST_LENGTH] = {0};
    
    authenticateKeyRequestBytes[0] = 0x27;
    authenticateKeyRequestBytes[1] = 0x0a;
    
    memcpy(authenticateKeyRequestBytes + 2, [data bytes], PASS_ACCESS_LIMIT_KEY_LENGTH);
    
    data = [NSData dataWithBytes:authenticateKeyRequestBytes length:sizeof(authenticateKeyRequestBytes)];
    
    error = [self sendData:data];
    
    if (error != Success)
    {
        return error;
    }

    error = [self receiveData:&data];
    
    if (error != Success)
    {
        return error;
    }
    
    bytes = (Byte *)[data bytes];
    
    if (bytes[0] != 0x67 || bytes[1] != 0x0a)
    {
        return NegativeResponse;
    }
    
    return Success;
}

//编码数据
- (BOOL)escapeInputData:(NSData *)inputData toOutputData:(NSData **)outputData
{
    if (!inputData || !outputData)
    {
        return NO;
    }
    
    long inputDataLength = [inputData length];
    
    if (inputDataLength < 1)
    {
        return NO;
    }
    
    long payloadBytesLength = inputDataLength + 9;
    
    long beforeEscapeBytesLength = payloadBytesLength + 2;
    
    Byte * beforeEscapeBytes = malloc(beforeEscapeBytesLength);
    
    beforeEscapeBytes[0] = (Byte)(payloadBytesLength >> 8);
    beforeEscapeBytes[1] = (Byte)(payloadBytesLength & 0x000000ff);
    
    beforeEscapeBytes[2] = 0x03;
    beforeEscapeBytes[3] = 0x08;
    beforeEscapeBytes[4] = 0x02;
    *(unsigned int *)(beforeEscapeBytes + 5) = 0xfa00da18;
    
    beforeEscapeBytes[9] = (Byte)(inputDataLength >> 8);
    beforeEscapeBytes[10] = (Byte)(inputDataLength & 0x000000ff);
    
    memcpy(beforeEscapeBytes + 11, [inputData bytes], inputDataLength);
    
    long afterEscapeBytesLength = 2 * beforeEscapeBytesLength + 2;
    Byte * afterEscapeBytes = malloc(afterEscapeBytesLength);
    
    int escapeCursor = 1;
    
    afterEscapeBytes[0] = 0xaa;
    
    for (int i = 0; i < beforeEscapeBytesLength; ++i)
    {
        if (beforeEscapeBytes[i] == 0x7d)
        {
            afterEscapeBytes[escapeCursor++] = 0x7d;
            afterEscapeBytes[escapeCursor++] = 0x01;
        }
        else if (beforeEscapeBytes[i] == 0xaa)
        {
            afterEscapeBytes[escapeCursor++] = 0x7d;
            afterEscapeBytes[escapeCursor++] = 0x02;
        }
        else if (beforeEscapeBytes[i] == 0x55)
        {
            afterEscapeBytes[escapeCursor++] = 0x7d;
            afterEscapeBytes[escapeCursor++] = 0x03;
        }
        else
        {
            afterEscapeBytes[escapeCursor++] = beforeEscapeBytes[i];
        }
    }
    
    afterEscapeBytes[escapeCursor++] = 0x55;
    
    *outputData = [NSData dataWithBytes:afterEscapeBytes length:escapeCursor];
    
    free(beforeEscapeBytes);
    free(afterEscapeBytes);
    
    return YES;
}

//解码数据
- (BOOL)unescapeInputData:(NSData *)inputData toOutputData:(NSData **)outputData
{
    if (!inputData || !outputData)
    {
        return NO;
    }
    
    long inputDataLength = [inputData length];
    
    if (inputDataLength < 13)
    {
        return NO;
    }
    
    Byte * inputBytes = (Byte *)[inputData bytes];
    
    if (inputBytes[0] != 0x55 || inputBytes[inputDataLength - 1] != 0xaa)
    {
        return NO;
    }
    
    long afterUnescapeBytesBufferLength = inputDataLength - 2;
    
    Byte * afterUnescapeBytesBuffer = malloc(afterUnescapeBytesBufferLength);
    
    int unescapeCursor = 0;
    
    for (int i = 1; i < inputDataLength - 1; ++i)
    {
        if (inputBytes[i] == 0x55 || inputBytes[i] == 0xaa)
        {
            free(afterUnescapeBytesBuffer);
            return NO;
        }
        
        if (inputBytes[i] == 0x7d)
        {
            if (inputBytes[i + 1] == 0x01)
            {
                afterUnescapeBytesBuffer[unescapeCursor++] = 0x7d;
            }
            else if (inputBytes[i + 1] == 0x02)
            {
                afterUnescapeBytesBuffer[unescapeCursor++] = 0xaa;
            }
            else if (inputBytes[i + 1] == 0x03)
            {
                afterUnescapeBytesBuffer[unescapeCursor++] = 0x55;
            }
            else
            {
                free(afterUnescapeBytesBuffer);
                return NO;
            }
            
            ++i;
        }
        else
        {
            afterUnescapeBytesBuffer[unescapeCursor++] = inputBytes[i];
        }
    }
    
    if (unescapeCursor < 11)
    {
        free(afterUnescapeBytesBuffer);
        return NO;
    }
    
    int payloadBytesLength = (afterUnescapeBytesBuffer[0] << 8) + afterUnescapeBytesBuffer[1];
    
    if (unescapeCursor - 2 != payloadBytesLength)
    {
        free(afterUnescapeBytesBuffer);
        return NO;
    }
    
    if (afterUnescapeBytesBuffer[2] != 0x03 || afterUnescapeBytesBuffer[3] != 0x09 || *(unsigned int *)(afterUnescapeBytesBuffer + 4) != 0x00fada18)
    {
        free(afterUnescapeBytesBuffer);
        return NO;
    }
    
    int outputBytesLength = (afterUnescapeBytesBuffer[8] << 8) + afterUnescapeBytesBuffer[9];
    
    if (payloadBytesLength - 8 != outputBytesLength)
    {
        free(afterUnescapeBytesBuffer);
        return NO;
    }
    
    *outputData = [NSData dataWithBytes:afterUnescapeBytesBuffer + 10 length:outputBytesLength];
    
    free(afterUnescapeBytesBuffer);
    
    return YES;
}

- (BOOL)fromSeed:(NSData *)seed toKey:(NSData **)key
{
    unsigned int mask = 0x7c1b2c30;
    
    if (!seed || !key)
    {
        return NO;
    }
    
    if ([seed length] != 4)
    {
        return NO;
    }
    
    Byte * seedBytes = (Byte *)[seed bytes];
    
    if (seedBytes[0] == 0 && seedBytes[1] == 0)
    {
        return NO;
    }
    
    unsigned int wort = (seedBytes[0] << 24) + (seedBytes[1] << 16) + (seedBytes[2] << 8) + seedBytes[3];
    
    for (int i = 0; i < 35; ++i)
    {
        if (wort & 0x80000000)
        {
            wort <<= 1;
            wort ^= mask;
        }
        else
        {
            wort <<= 1;
        }
    }
    
    Byte * keyBytesReversed = (Byte*)&wort;
    
    Byte keyBytes[4] = {0};
    
    for (int i = 0; i < 4; ++i)
    {
        keyBytes[3 - i] = keyBytesReversed[i];
    }
    
    *key = [NSData dataWithBytes:keyBytes length:sizeof(keyBytes)];
    
    return YES;
}

//读取数据
- (Error)readData:(NSData **)data byIdentifier:(unsigned short)identifier
{
    Error error = Success;
    
    if (!data)
    {
        return InvalidParameter;
    }
        
    Byte readDataRequestBytes[READ_DATA_REQUEST_LENGTH] = {0};
    
    readDataRequestBytes[0] = READ_DATA_REQUEST_IDENTIFIER;
    readDataRequestBytes[1] = (Byte)(identifier >> 8);
    readDataRequestBytes[2] = (Byte)(identifier & 0x00ff);
    
    NSData * tempData = [NSData dataWithBytes:readDataRequestBytes length:sizeof(readDataRequestBytes)];
    
    error = [self sendData:tempData];
    
    if (error != Success)
    {
        return error;
    }
    
    error = [self receiveData:&tempData];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte * bytes = (Byte *)[tempData bytes];
    
    if (bytes[0] != READ_DATA_RESPONSE_IDENTIFIER)
    {        
        return NegativeResponse;
    }
    
    unsigned short responseIdentifier = (bytes[1] << 8) + bytes[2];
    
    if (responseIdentifier != identifier)
    {
        return NegativeResponse;
    }
    
    *data = [NSData dataWithBytes:bytes + 3 length:[tempData length] - 3];
    
    return Success;
}

//读取冻结帧
- (Error)readFrozenFramesToData:(NSData **)framesData byDTCData:(NSData *)dtcData
{
    Error error = Success;
    
    if (!framesData || !dtcData)
    {
        return InvalidParameter;
    }
    
    if ([dtcData length] != READ_DTCS_FULL_CODE_LENGTH)
    {
        return InvalidParameter;
    }
    
    Byte readFrozenFramesRequestBytes[READ_FROZEN_FRAMES_REQUEST_LENGTH] = {0};
    
    readFrozenFramesRequestBytes[0] = READ_FROZEN_FRAMES_REQUEST_IDENTIFIER;
    readFrozenFramesRequestBytes[1] = READ_FROZEN_FRAMES_PARAMETER;
    memcpy(readFrozenFramesRequestBytes + 2, [dtcData bytes], READ_DTCS_EFFECTIVE_CODE_LENGTH);
    
    NSData * data = [NSData dataWithBytes:readFrozenFramesRequestBytes length:sizeof(readFrozenFramesRequestBytes)];
    
    error = [self sendData:data];
    
    if (error != Success)
    {
        return error;
    }
    
    error = [self receiveData:&data];
    
    if (error != Success)
    {
        return error;
    }

    Byte * bytes = (Byte *)[data bytes];
    
    if (bytes[0] != READ_FROZEN_FRAMES_RESPONSE_IDENTIFIER)
    {
        return NegativeResponse;
    }
    
    if (bytes[1] != READ_FROZEN_FRAMES_PARAMETER)
    {
        return NegativeResponse;
    }
    
    if (memcmp(bytes + 2, [dtcData bytes], READ_DTCS_EFFECTIVE_CODE_LENGTH))
    {
        return NegativeResponse;
    }
    
    if ([data length] < 7)
    {
        *framesData = [[NSData alloc] init];
        
        return Success;
    }
    
    *framesData = [NSData dataWithBytes:bytes + 6 length:[data length] - 6];
    
    return Success;
}

//清除故障
- (Error)clearDTC
{
    Error error = Success;
    
    Byte clearDTCsReuqestBytes[CLEAR_DTCS_REQUEST_LENGTH] = {CLEAR_DTCS_REQUEST_IDENTIFIER, CLEAR_DTCS_PARAMETER_1, CLEAR_DTCS_PARAMETER_2, CLEAR_DTCS_PARAMETER_3};
    
    NSData * data = [NSData dataWithBytes:clearDTCsReuqestBytes length:sizeof(clearDTCsReuqestBytes)];
    
    error = [self sendData:data];
    
    if (error != Success)
    {
        return error;
    }
    
    error = [self receiveData:&data];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte * bytes = (Byte *)[data bytes];
    
    if (bytes[0] != CLEAR_DTCS_RESPONSE_IDENTIFIER)
    {
        return NegativeResponse;
    }
    
    return Success;    
}

//开始IO控制
- (Error)startIoControlWithData:(NSData *)data byIdentifier:(unsigned short)identifier
{
    Error error = Success;
    
    if (!data)
    {
        return InvalidParameter;
    }
    
    if ([data length] != CONTROL_IO_CODE_LENGTH)
    {
        return InvalidParameter;
    }
    
    error = [self changeSessionMode:0x40];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte startIoControlRequestBytes[CONTROL_IO_START_REQUEST_LENGTH] = {0};
    startIoControlRequestBytes[0] = CONTROL_IO_REQUEST_IDENTIFIER;
    startIoControlRequestBytes[1] = (identifier >> 8);
    startIoControlRequestBytes[2] = (identifier & 0x00ff);
    startIoControlRequestBytes[3] = CONTROL_IO_PARAMETER_START;
    memcpy(startIoControlRequestBytes + 4, [data bytes], CONTROL_IO_CODE_LENGTH);
    
    NSData * tempData =[NSData dataWithBytes:startIoControlRequestBytes length:sizeof(startIoControlRequestBytes)];
    
    error = [self sendData:tempData];
    
    if (error != Success)
    {
        return error;
    }
    
    error = [self receiveData:&tempData];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte * bytes = (Byte *)[tempData bytes];
    
    if (bytes[0] != CONTROL_IO_RESPONSE_IDENTIFIER)
    {
        return NegativeResponse;
    }
    
    unsigned short responseIdentifier = (bytes[1] << 8) + bytes[2];
    
    if (responseIdentifier != identifier)
    {
        return NegativeResponse;
    }
    
    if (bytes[3] != CONTROL_IO_PARAMETER_START)
    {
        return NegativeResponse;
    }
    
    if (bytes[4] != CONTROL_IO_SUCCESS)
    {
        return IoControlFailure;
    }
    
    return Success;
}

//停止IO控制
- (Error)stopIoControlByIdentifier:(unsigned short)identifier
{
    Error error = Success;
    
    if (![self changeSessionMode:0x40])
    {
        return error;
    }
    
    Byte stopIoControlRequestBytes[CONTROL_IO_STOP_REQUEST_LENGTH] = {0};
    stopIoControlRequestBytes[0] = CONTROL_IO_REQUEST_IDENTIFIER;
    stopIoControlRequestBytes[1] = (Byte)(identifier >> 8);
    stopIoControlRequestBytes[2] = (Byte)(identifier & 0x00ff);
    stopIoControlRequestBytes[3] = CONTROL_IO_PARAMETER_STOP;
    
    NSData * data = [NSData dataWithBytes:stopIoControlRequestBytes length:sizeof(stopIoControlRequestBytes)];
    
    error = [self sendData:data];
    
    if (error != Success)
    {
        return error;
    }

    error = [self receiveData:&data];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte * bytes = (Byte *)[data bytes];
    
    if (bytes[0] != CONTROL_IO_RESPONSE_IDENTIFIER)
    {
        return NegativeResponse;
    }
    
    unsigned short responseIdentifier = (bytes[1] << 8) + bytes[2];
    
    if (responseIdentifier != identifier)
    {
        return NegativeResponse;
    }
    
    if (bytes[3] != CONTROL_IO_SUCCESS)
    {
        return IoControlFailure;
    }
    
    return Success;
}

//例程控制
- (Error)startRoutineControlByIdentifier:(unsigned short)identifier withData:(NSData *)data
{
    Error error = Success;
    
    NSInteger startRoutineControlRequestBytesLength = CONTROL_ROUTINE_REQUEST_PREFIX_LENGTH + (data ? [data length] : 0);
    
    Byte * startRoutineControlReuqestBytes = malloc(startRoutineControlRequestBytesLength);
    startRoutineControlReuqestBytes[0] = CONTROL_ROUTINE_REQUEST_IDENTIFIER;
    startRoutineControlReuqestBytes[1] = CONTROL_ROUTINE_PARAMETER_START;
    startRoutineControlReuqestBytes[2] = (Byte)(identifier >> 8);
    startRoutineControlReuqestBytes[3] = (Byte)(identifier & 0xff);
    
    memcpy(startRoutineControlReuqestBytes + CONTROL_ROUTINE_REQUEST_PREFIX_LENGTH, [data bytes], [data length]);
    
    NSData * tempData = [NSData dataWithBytesNoCopy:startRoutineControlReuqestBytes length:startRoutineControlRequestBytesLength];
    
    error = [self sendData:tempData];
    
    if (error != Success)
    {
        return error;
    }

    error = [self receiveData:&tempData];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte * bytes = (Byte *)[tempData bytes];
    
    if (bytes[0] != CONTROL_ROUTINE_RESPONSE_IDENTIFIER)
    {
        return NegativeResponse;
    }
    
    if (bytes[1] != CONTROL_ROUTINE_PARAMETER_START)
    {
        return NegativeResponse;
    }
    
    unsigned short responseIdentifier = (bytes[2] << 8) + bytes[3];
    
    if (responseIdentifier != identifier)
    {
        return NegativeResponse;
    }
    
    return Success;
}

//读取例程控制状态
- (Error)getRoutineControlStatusByIdentifier:(unsigned short)identifier
{
    Error error = Success;
    
    Byte routineControlStatusReuqestBytes[CONTROL_ROUTINE_REQUEST_PREFIX_LENGTH] = {0};
    routineControlStatusReuqestBytes[0] = CONTROL_ROUTINE_REQUEST_IDENTIFIER;
    routineControlStatusReuqestBytes[1] = CONTROL_ROUTINE_PARAMETER_STATUS;
    routineControlStatusReuqestBytes[2] = (Byte)(identifier >> 8);
    routineControlStatusReuqestBytes[3] = (Byte)(identifier & 0xff);
    
    NSData * tempData = [NSData dataWithBytes:routineControlStatusReuqestBytes length:sizeof(routineControlStatusReuqestBytes)];
    
    error = [self sendData:tempData];
    
    if (error != Success)
    {
        return error;
    }

    error = [self receiveData:&tempData];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte * bytes = (Byte *)[tempData bytes];
    
    if (bytes[0] != CONTROL_ROUTINE_RESPONSE_IDENTIFIER)
    {
        return NegativeResponse;
    }
    
    if (bytes[1] != CONTROL_ROUTINE_PARAMETER_STATUS)
    {
        return NegativeResponse;
    }
    
    unsigned short responseIdentifier = (bytes[2] << 8) + bytes[3];
    
    if (responseIdentifier != identifier)
    {
        return NegativeResponse;
    }
    
    if (bytes[4] == 2)
    {
        return Success;
    }
    else
    {
        return RoutineControlFailure;
    }
}

//停止例程控制
- (Error)stopRoutineControlByIdentifier:(unsigned short)identifier
{
    Error error = Success;
    
    Byte routineControlStatusReuqestBytes[CONTROL_ROUTINE_REQUEST_PREFIX_LENGTH] = {0};
    routineControlStatusReuqestBytes[0] = CONTROL_ROUTINE_REQUEST_IDENTIFIER;
    routineControlStatusReuqestBytes[1] = CONTROL_ROUTINE_PARAMETER_STOP;
    routineControlStatusReuqestBytes[2] = (Byte)(identifier >> 8);
    routineControlStatusReuqestBytes[3] = (Byte)(identifier & 0xff);
    
    NSData * data = [NSData dataWithBytes:routineControlStatusReuqestBytes length:sizeof(routineControlStatusReuqestBytes)];
    
    error = [self sendData:data];
    
    if (error != Success)
    {
        return error;
    }

    error = [self receiveData:&data];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte * bytes = (Byte *)[data bytes];
    
    if (bytes[0] != CONTROL_ROUTINE_RESPONSE_IDENTIFIER)
    {
        return NegativeResponse;
    }
    
    if (bytes[1] != CONTROL_ROUTINE_PARAMETER_STOP)
    {
        return NegativeResponse;
    }
    
    unsigned short responseIdentifier = (bytes[2] << 8) + bytes[3];
    
    if (responseIdentifier != identifier)
    {
        return NegativeResponse;
    }

    return Success;
}

//读取当前故障
- (Error)readCurrentDTCToArray:(NSArray **)array
{
    Error error = Success;
    
    if (!array)
    {
        return InvalidParameter;
    }
    
    Byte readDTCsRequestBytes[] = {READ_DTCS_REQUEST_IDENTIFIER, READ_DTCS_PARAMETER, READ_DTCS_MASK_CURRENT};
    
    NSData * data = [NSData dataWithBytes:readDTCsRequestBytes length:sizeof(readDTCsRequestBytes)];
    
    error = [self sendData:data];
    
    if (error != Success)
    {
        return error;
    }
    
    error = [self receiveData:&data];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte * bytes = (Byte *)[data bytes];
    
    if (bytes[0] != READ_DTCS_RESPONSE_IDENTIFIER)
    {
        return NegativeResponse;
    }
    
    if (bytes[1] != READ_DTCS_PARAMETER)
    {
        return NegativeResponse;
    }
    
    if ([data length] == 3)
    {
        *array = [[NSArray alloc] init];
        
        return Success;
    }
    
    Byte * cursor = bytes + 3;
    
    NSMutableArray * dtcsArray = [[NSMutableArray alloc] init];
    
    while (cursor < (bytes + [data length]))
    {
        NSMutableString * dtcCode = [[NSMutableString alloc] init];
        
        unsigned short dtcNumber = (cursor[0] << 8) + cursor[1];
        
        [dtcCode appendFormat:@"P%04X", dtcNumber];
        
        NSData * dtcData = [NSData dataWithBytes:cursor length:READ_DTCS_FULL_CODE_LENGTH];
        
        NSDictionary * dtcDictionary = [NSDictionary dictionaryWithObjectsAndKeys:dtcCode, @"code", dtcData, @"data", nil];
        
        [dtcsArray addObject:dtcDictionary];
        
        cursor += READ_DTCS_FULL_CODE_LENGTH;
    }
    
    *array = [NSArray arrayWithArray:dtcsArray];
    
    return Success;
}

//读取历史故障
- (Error)readConfirmedDTCToArray:(NSArray **)array
{
    Error error = Success;
    
    if (!array)
    {
        return InvalidParameter;
    }
    
    Byte readDTCsRequestBytes[] = {READ_DTCS_REQUEST_IDENTIFIER, READ_DTCS_PARAMETER, READ_DTCS_MASK_CONFIRMED};
    
    NSData * data = [NSData dataWithBytes:readDTCsRequestBytes length:sizeof(readDTCsRequestBytes)];
    
    error = [self sendData:data];
    
    if (error != Success)
    {
        return error;
    }

    error = [self receiveData:&data];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte * bytes = (Byte *)[data bytes];
    
    if (bytes[0] != READ_DTCS_RESPONSE_IDENTIFIER)
    {
        return NegativeResponse;
    }
    
    if (bytes[1] != READ_DTCS_PARAMETER)
    {
        return NegativeResponse;
    }

    if ([data length] == 3)
    {
        *array = [[NSArray alloc] init];
        
        return Success;
    }
    
    Byte * cursor = bytes + 3;
    
    NSMutableArray * dtcsArray = [[NSMutableArray alloc] init];
    
    while (cursor < (bytes + [data length]))
    {
        NSMutableString * dtcCode = [[NSMutableString alloc] init];
        
        unsigned short dtcNumber = (cursor[0] << 8) + cursor[1];
        
        [dtcCode appendFormat:@"P%04X", dtcNumber];
        
        NSData * dtcData = [NSData dataWithBytes:cursor length:READ_DTCS_FULL_CODE_LENGTH];
        
        NSDictionary * dtcDictionary = [NSDictionary dictionaryWithObjectsAndKeys:dtcCode, @"code", dtcData, @"data", nil];
        
        [dtcsArray addObject:dtcDictionary];
        
        cursor += READ_DTCS_FULL_CODE_LENGTH;
    }
    
    *array = [NSArray arrayWithArray:dtcsArray];
    
    return Success;
}

//根据错误类型格式化错误文本
- (NSString *)getErrorMessage:(Error)error
{
    switch (error)
    {
        case Timeout:
            return @"网络连接失败, 请检查无线网络连接状态并确保信号质量良好.";
        case NegativeResponse:
            return @"条件不满足, 操作失败, 请检查后再试.";
        case TransmissionFailure:
            return @"数据传输失败, 请检查配套设备与车载OBD接口是否接触良好.";
        case NoResponse:
            return @"数据传输失败, 请检查配套设备与车载OBD接口是否接触良好.";
        case InvalidParameter:
            return @"数据传输发生了内部错误, 本次操作被终止.";
        case InvalidProtocol:
            return @"数据传输失败, 请确保连接设备是本软件的配套设备.";
        case AuthenticationFailure:
            return @"数据认证失败, 请确保连接设备是本软件的配套设备.";
        case InnerError:
            return @"数据传输发生了内部错误, 本次操作被终止.";
        case IoControlFailure:
            return @"次次控制操作失败.";
        case RoutineControlFailure:
            return @"本次控制操作失败.";
        case RoutineControlTimeout:
            return @"条件不满足, 操作超时, 请稍后再试.";
        case Canceled:
            return @"用户取消了本次操作.";
        default:
            return nil;
    }
}

//读取ECU数据
- (Error)readData:(NSData **)data byAddress:(NSData *)address andLength:(ushort)length
{
    Error error = Success;
    
    if (!data || !address)
    {
        return InvalidParameter;
    }
    
    if ([address length] != 3)
    {
        return InvalidParameter;
    }
    
    if (!length)
    {
        return InvalidParameter;
    }
    
    Byte readDataRequestBytes[7] = {0};
    
    readDataRequestBytes[0] = 0x23;
    readDataRequestBytes[1] = 0x23;
    readDataRequestBytes[2] = ((Byte *)[address bytes])[0];
    readDataRequestBytes[3] = ((Byte *)[address bytes])[1];
    readDataRequestBytes[4] = ((Byte *)[address bytes])[2];
    readDataRequestBytes[5] = (length >> 8);
    readDataRequestBytes[6] = (Byte)length;
    
    NSData * tempData = [NSData dataWithBytes:readDataRequestBytes length:sizeof(readDataRequestBytes)];
    
    error = [self sendData:tempData];
    
    if (error != Success)
    {
        return error;
    }
    
    error = [self receiveData:&tempData];
    
    if (error != Success)
    {
        return error;
    }
    
    Byte * bytes = (Byte *)[tempData bytes];
    
    if (bytes[0] != 0x63)
    {
        return NegativeResponse;
    }
    
    if ([tempData length] != length + 1)
    {
        return InvalidProtocol;
    }
    
    *data = [NSData dataWithBytes:bytes + 1 length:[tempData length] - 1];
    
    return Success;
}

//析构函数
- (void)finalize
{
    if (mySocket != -1)
    {
        [self disconnectFromServer];
        mySocket = -1;
    }
    
    [super finalize];
}

@end

