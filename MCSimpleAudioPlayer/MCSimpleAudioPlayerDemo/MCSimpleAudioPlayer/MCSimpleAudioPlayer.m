//
//  MCSimpleAudioPlayer.m
//  MCSimpleAudioPlayer
//
//  Created by Chengyin on 14-7-27.
//  Copyright (c) 2014年 Chengyin. All rights reserved.
//

#import "MCSimpleAudioPlayer.h"
#import "MCAudioSession.h"
#import "MCAudioOutputQueue.h"
#import "MCAudioBuffer.h"
#import <pthread.h>

#import "MCAudioInputQueue.h"

static const NSTimeInterval bufferDuration = 0.2;

@interface MCSimpleAudioPlayer ()<MCAudioInputQueueDelegate>
{
@private
    NSThread *_thread;
    pthread_mutex_t _mutex;
	pthread_cond_t _cond;
    
    MCSAPStatus _status;
    
    unsigned long long _fileSize;
    unsigned long long _offset;
    NSFileHandle *_fileHandler;
    
    UInt32 _bufferSize;
    MCAudioBuffer *_buffer;
    
    MCAudioOutputQueue *_outputQueue;
    
    BOOL _started;
    BOOL _pauseRequired;
    BOOL _stopRequired;
    BOOL _pausedByInterrupt;
    BOOL _usingAudioFile;
    
    BOOL _seekRequired;
    NSTimeInterval _seekTime;
    NSTimeInterval _timingOffset;
    
    //inptu & output Queue added
     MCAudioInputQueue *_recorder;
    AudioStreamBasicDescription _format;
    AudioStreamBasicDescription defaultOutputFormat;
    UInt32 bufferSizeOut;
}
@end

@implementation MCSimpleAudioPlayer
@dynamic status;
@synthesize failed = _failed;
@synthesize fileType = _fileType;
@synthesize filePath = _filePath;
@dynamic isPlayingOrWaiting;
@dynamic duration;
@dynamic progress;

#pragma mark - init & dealloc
- (instancetype)initWithFilePath:(NSString *)filePath fileType:(AudioFileTypeID)fileType
{
    self = [super init];
    if (self)
    {
//        _status = MCSAPStatusStopped;
//        
//        _filePath = filePath;
//        _fileType = fileType;
//        
//        _fileHandler = [NSFileHandle fileHandleForReadingAtPath:_filePath];
//        _fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:_filePath error:nil] fileSize];
//        if (_fileHandler && _fileSize > 0)
//        {
//            _buffer = [MCAudioBuffer buffer];
//        }
//        else
//        {
//            [_fileHandler closeFile];
//            _failed = YES;
//        }
        _bufferSize = 3996;
        _buffer = [MCAudioBuffer buffer];
        
    }
    return self;
}

- (void)dealloc
{
    [self cleanup];
    [_fileHandler closeFile];
}

- (void)cleanup
{
    //reset file
    _offset = 0;
    [_fileHandler seekToFileOffset:0];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MCAudioSessionInterruptionNotification object:nil];
    
    //clean buffer
    [_buffer clean];
    
    _usingAudioFile = NO;
    //close audioFileStream
//    [_audioFileStream close];
//    _audioFileStream = nil;
    
    //close audiofile
//    [_audioFile close];
//    _audioFile = nil;
//    
    //stop audioQueue
    [_outputQueue stop:YES];
    _outputQueue = nil;
    
    //destory mutex & cond
    [self _mutexDestory];
    
    _started = NO;
    _timingOffset = 0;
    _seekTime = 0;
    _seekRequired = NO;
    _pauseRequired = NO;
    _stopRequired = NO;
    
    //reset status
    [self setStatusInternal:MCSAPStatusStopped];
}

#pragma mark - status
- (BOOL)isPlayingOrWaiting
{
    return self.status == MCSAPStatusWaiting || self.status == MCSAPStatusPlaying || self.status == MCSAPStatusFlushing;
}

- (MCSAPStatus)status
{
    return _status;
}

- (void)setStatusInternal:(MCSAPStatus)status
{
    if (_status == status)
    {
        return;
    }
    
    [self willChangeValueForKey:@"status"];
    _status = status;
    [self didChangeValueForKey:@"status"];
}

#pragma mark - mutex
- (void)_mutexInit
{
    pthread_mutex_init(&_mutex, NULL);
    pthread_cond_init(&_cond, NULL);
}

- (void)_mutexDestory
{
    pthread_mutex_destroy(&_mutex);
    pthread_cond_destroy(&_cond);
}

- (void)_mutexWait
{
    pthread_mutex_lock(&_mutex);
    pthread_cond_wait(&_cond, &_mutex);
	pthread_mutex_unlock(&_mutex);
}

- (void)_mutexSignal
{
    pthread_mutex_lock(&_mutex);
    pthread_cond_signal(&_cond);
    pthread_mutex_unlock(&_mutex);
}

#pragma mark - thread
- (BOOL)createAudioQueue
{
    if (_outputQueue)
    {
        return YES;
    }
    
    defaultOutputFormat.mFormatID = kAudioFormatLinearPCM;
    defaultOutputFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    defaultOutputFormat.mBitsPerChannel = 16;
    defaultOutputFormat.mChannelsPerFrame = 1;
    
    defaultOutputFormat.mFramesPerPacket = 1;
    defaultOutputFormat.mBytesPerFrame = defaultOutputFormat.mChannelsPerFrame * (defaultOutputFormat.mBitsPerChannel / 8);
    defaultOutputFormat.mBytesPerPacket = defaultOutputFormat.mFramesPerPacket * defaultOutputFormat.mBytesPerFrame;
    defaultOutputFormat.mSampleRate = 8000.0f;
    
    bufferSizeOut = defaultOutputFormat.mBitsPerChannel * defaultOutputFormat.mChannelsPerFrame * defaultOutputFormat.mSampleRate * bufferDuration / 8;


    _recorder = [MCAudioInputQueue inputQueueWithFormat:defaultOutputFormat bufferDuration:bufferDuration delegate:self];
    _recorder.meteringEnabled = YES;
    [_recorder start];
    if (!_recorder.available) {
        _recorder = nil;
        return NO;
    }
    
    _outputQueue = [[MCAudioOutputQueue alloc] initWithFormat:defaultOutputFormat bufferSize:3996 macgicCookie:nil];
    if (!(_outputQueue.available && _recorder.available))
    {
        _outputQueue = nil;
        _recorder = nil;
        return NO;
    }

    NSLog(@"ceatQueue %u", (unsigned int)bufferSizeOut);
    _bufferSize = 3996;
    
    return YES;
}

- (void)threadMain
{
    _failed = YES;
    NSError *error = nil;
    //set audiosession category
    if ([[MCAudioSession sharedInstance] setCategory:kAudioSessionCategory_PlayAndRecord error:NULL])
    {
        //active audiosession
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptHandler:) name:MCAudioSessionInterruptionNotification object:nil];
        if ([[MCAudioSession sharedInstance] setActive:YES error:NULL])
        {
            if (!error)
            {
                _failed = NO;
//                _audioFileStream.delegate = self;
            }
        }
    }
    
    if (_failed)
    {
        [self cleanup];
        return;
    }
    
    [self setStatusInternal:MCSAPStatusWaiting];
    BOOL isEof = NO;
    while (self.status != MCSAPStatusStopped && !_failed && _started)
    {
        @autoreleasepool
        {
            //read file & parse
            if (![self createAudioQueue])
            {
                _failed = YES;
                break;
            }
            
            if (!_outputQueue)
            {
                continue;
            }
            
            if (self.status == MCSAPStatusFlushing && !_outputQueue.isRunning)
            {
                break;
            }
            
            //stop
            if (_stopRequired)
            {
                _stopRequired = NO;
                _started = NO;
                [_outputQueue stop:YES];
                break;
            }
            
            //pause
            if (_pauseRequired)
            {
                [self setStatusInternal:MCSAPStatusPaused];
                [_outputQueue pause];
                [self _mutexWait];
                _pauseRequired = NO;
            }
            
            //play
            if ([_buffer bufferedSize] >= _bufferSize || isEof)
            {
                UInt32 packetCount;
                AudioStreamPacketDescription *desces = NULL;
                NSData *data = [_buffer dequeueDataWithSize:_bufferSize packetCount:&packetCount descriptions:&desces];
                if (packetCount != 0)
                {
                    [self setStatusInternal:MCSAPStatusPlaying];
                    _failed = ![_outputQueue playData:data packetCount:packetCount packetDescriptions:desces isEof:isEof];
                    free(desces);
                    if (_failed)
                    {
                        break;
                    }
                    
                    if (![_buffer hasData] && isEof && _outputQueue.isRunning)
                    {
                        [_outputQueue stop:NO];
                        [self setStatusInternal:MCSAPStatusFlushing];
                    }
                }
                else if (isEof)
                {
                    //wait for end
                    if (![_buffer hasData] && _outputQueue.isRunning)
                    {
                        [_outputQueue stop:NO];
                        [self setStatusInternal:MCSAPStatusFlushing];
                    }
                }
                else
                {
                    _failed = YES;
                    break;
                }
            }
            
            //seek
//            if (_seekRequired && self.duration != 0)
//            {
//                [self setStatusInternal:MCSAPStatusWaiting];
//                
//                _timingOffset = _seekTime - _audioQueue.playedTime;
//                [_buffer clean];
//                if (_usingAudioFile)
//                {
//                    [_audioFile seekToTime:_seekTime];
//                }
//                else
//                {
//                    _offset = [_audioFileStream seekToTime:&_seekTime];
//                    [_fileHandler seekToFileOffset:_offset];
//                }
//                _seekRequired = NO;
//                [_audioQueue reset];
//            }
        }
    }
    
    //clean
    [self cleanup];
}


#pragma mark - interrupt
- (void)interruptHandler:(NSNotification *)notification
{
    UInt32 interruptionState = [notification.userInfo[MCAudioSessionInterruptionStateKey] unsignedIntValue];
    
    if (interruptionState == kAudioSessionBeginInterruption)
    {
        _pausedByInterrupt = YES;
        [_outputQueue pause];
        [self setStatusInternal:MCSAPStatusPaused];
        
    }
    else if (interruptionState == kAudioSessionEndInterruption)
    {
        AudioSessionInterruptionType interruptionType = [notification.userInfo[MCAudioSessionInterruptionTypeKey] unsignedIntValue];
        if (interruptionType == kAudioSessionInterruptionType_ShouldResume)
        {
            if (self.status == MCSAPStatusPaused && _pausedByInterrupt)
            {
                if ([[MCAudioSession sharedInstance] setActive:YES error:NULL])
                {
                    [self play];
                }
            }
        }
    }
}

#pragma mark - parser
//AudioFileStream解析完成的数据都被存储到了_buffer中
//- (void)audioFileStream:(MCAudioFileStream *)audioFileStream audioDataParsed:(NSArray *)audioData
//{
//    [_buffer enqueueFromDataArray:audioData];
//}

/** inputQueue delegate implementation */
- (void)inputQueue:(MCAudioInputQueue *)inputQueue inputData:(NSData *)data numberOfPackets:(UInt32)numberOfPackets inPacketDescs:(const AudioStreamPacketDescription *)inPacketDescs
{
    MCParsedAudioData *parsedData = [MCParsedAudioData parsedAudioDataWithBytes:data]; //
    
    [_buffer enqueueData:parsedData];
}

- (void)inputQueue:(MCAudioInputQueue *)inputQueue errorOccur:(NSError *)error
{
    
}

#pragma mark - progress
- (NSTimeInterval)progress
{
    if (_seekRequired)
    {
        return _seekTime;
    }
    return _timingOffset + _outputQueue.playedTime;
}

- (void)setProgress:(NSTimeInterval)progress
{
    _seekRequired = YES;
    _seekTime = progress;
}

- (NSTimeInterval)duration
{
//    return _usingAudioFile ? _audioFile.duration : _audioFileStream.duration;
    return 0.2;
}

#pragma mark - method
- (void)play
{
    if (!_started)
    {
        _started = YES;
        [self _mutexInit];
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMain) object:nil];
        [_thread start];
    }
    else
    {
        if (_status == MCSAPStatusPaused || _pauseRequired)
        {
            _pausedByInterrupt = NO;
            _pauseRequired = NO;
            if ([[MCAudioSession sharedInstance] setActive:YES error:NULL])
            {
                [[MCAudioSession sharedInstance] setCategory:kAudioSessionCategory_PlayAndRecord error:NULL];
                [self _resume];
            }
        }
    }
}

- (void)_resume
{
    [_outputQueue resume];
    [self _mutexSignal];
}

- (void)pause
{
    if (self.isPlayingOrWaiting && self.status != MCSAPStatusFlushing)
    {
        _pauseRequired = YES;
    }
}

- (void)stop
{
    _stopRequired = YES;
    [self _mutexSignal];
}

@end
