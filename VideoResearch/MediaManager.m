//
//  MediaManager.m
//  AddBackgroundMusic
//
//  Created by Shelin on 15/11/25.
//  Copyright © 2015年 GreatGate. All rights reserved.
//

#import "MediaManager.h"
#import <AVFoundation/AVFoundation.h>

#define MediaFileName @"MixVideo.mov"


@implementation MediaManager

+ (void)addBackgroundMiusicWithVideoUrlStr:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl andCaptureVideoWithRange:(NSRange)videoRange completion:(MixcompletionBlock)completionHandle {

    //AVURLAsset此类主要用于获取媒体信息，包括视频、声音等
    AVURLAsset* audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    //创建AVMutableComposition对象来添加视频音频资源的AVMutableCompositionTrack
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    //CMTimeRangeMake(start, duration),start起始时间，duration时长，都是CMTime类型
    //CMTimeMake(int64_t value, int32_t timescale)，返回CMTime，value视频的一个总帧数，timescale是指每秒视频播放的帧数，视频播放速率，（value / timescale）才是视频实际的秒数时长，timescale一般情况下不改变，截取视频长度通过改变value的值
    //CMTimeMakeWithSeconds(Float64 seconds, int32_t preferredTimeScale)，返回CMTime，seconds截取时长（单位秒），preferredTimeScale每秒帧数
    
    //开始位置startTime
    CMTime startTime = CMTimeMakeWithSeconds(videoRange.location, videoAsset.duration.timescale);
    //截取长度videoDuration
    CMTime videoDuration = CMTimeMakeWithSeconds(videoRange.length, videoAsset.duration.timescale);
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(startTime, videoDuration);
    
    //视频采集compositionVideoTrack
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
#warning 避免数组越界 tracksWithMediaType 找不到对应的文件时候返回空数组
    //TimeRange截取的范围长度
    //ofTrack来源
    //atTime插放在视频的时间位置
    [compositionVideoTrack insertTimeRange:videoTimeRange
                                   ofTrack:([videoAsset tracksWithMediaType:AVMediaTypeVideo].count>0) ? [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject : nil
                                    atTime:kCMTimeZero
                                     error:nil];
    
    /*
     //视频声音采集(也可不执行这段代码不采集视频音轨，合并后的视频文件将没有视频原来的声音)
     
     AVMutableCompositionTrack *compositionVoiceTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
     
     [compositionVoiceTrack insertTimeRange:videoTimeRange ofTrack:([videoAsset tracksWithMediaType:AVMediaTypeAudio].count>0)?[videoAsset tracksWithMediaType:AVMediaTypeAudio].firstObject:nil atTime:kCMTimeZero error:nil];
     
     */
    
    
    //声音长度截取范围==视频长度
    CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, videoDuration);
    
    //音频采集compositionCommentaryTrack
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [compositionAudioTrack insertTimeRange:audioTimeRange ofTrack:([audioAsset tracksWithMediaType:AVMediaTypeAudio].count > 0) ? [audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject : nil atTime:kCMTimeZero error:nil];
    
    //AVAssetExportSession用于合并文件，导出合并后文件，presetName文件的输出类型
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
    
    NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:MediaFileName];
    //混合后的视频输出路径
    NSURL *outPutUrl = [NSURL fileURLWithPath:outPutPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
    }
    
    //输出视频格式 AVFileTypeMPEG4 AVFileTypeQuickTimeMovie...
    assetExportSession.outputFileType = AVFileTypeQuickTimeMovie;
//    NSArray *fileTypes = assetExportSession.
    
    assetExportSession.outputURL = outPutUrl;
    //输出文件是否网络优化
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        completionHandle();
    }];
}

//合并音频
+ (void)meargeAudioWidthUrlArray:(NSArray<NSURL*>*)audioUrlArray resultBlock:(void (^)(NSString *filePath))resultBlock
{
    //创建可变的音频视频组合
    AVMutableComposition *composition =[AVMutableComposition composition];
    AVMutableAudioMix *audioMix =[AVMutableAudioMix audioMix];
    NSMutableArray *audioMixParams = [NSMutableArray array];

    
    
    
    NSInteger i = 0;
    for (NSURL *audioUrl in audioUrlArray) {
        AVURLAsset* audioAsset =[[AVURLAsset alloc]initWithURL:audioUrl options:nil];
        
        CGFloat sec = CMTimeGetSeconds(audioAsset.duration);
        CGFloat timeDuration = i == 0 ? sec : sec / 2;
        CGFloat timeScale = audioAsset.duration.timescale;
        CMTime startTime = kCMTimeZero;
        if  (i == 1) {
            startTime = CMTimeMake(5 * timeScale, timeScale);
        } else if (i == 2) {
            startTime = CMTimeMake(10 * timeScale, timeScale);
        }
        
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
        AVMutableCompositionTrack   *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                           preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSArray * assetTrackArray = [audioAsset tracksWithMediaType:AVMediaTypeAudio];
        if ([assetTrackArray count] > 0) {
            
            AVAssetTrack * assetTrack = assetTrackArray[0];
            [audioTrack insertTimeRange:timeRange
                                ofTrack:assetTrack
                                 atTime:startTime
                                  error:nil];
            
            //设置音量
            //AVMutableAudioMixInputParameters（输入参数可变的音频混合）
            //audioMixInputParametersWithTrack（音频混音输入参数与轨道）
            AVMutableAudioMixInputParameters *trackMix =[AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
            
            CGFloat volume = 0.5;
            if (i == 1) {
                volume = 0.2;
            } else if (i == 2) {
                volume = 1.0;
            }
            
            [trackMix setVolume:volume atTime:kCMTimeZero];
            //素材加入数组
            [audioMixParams addObject:trackMix];
        }
        
        i++;
        
    }
    
    audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];//从数组里取出处理后的音频轨道参数

    
    NSString *outputFilePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/mergeAudio.mp4"];
    
    [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    NSURL   *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    
    AVAssetExportSession* assetExport =[[AVAssetExportSession alloc]initWithAsset:composition
                                                                       presetName:AVAssetExportPresetMediumQuality];
    assetExport.audioMix = audioMix;
    assetExport.outputFileType = AVFileTypeMPEG4;
    assetExport.outputURL = outputFileUrl;
    assetExport.shouldOptimizeForNetworkUse= YES;
    
    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         switch ([assetExport status]) {
             case AVAssetExportSessionStatusFailed: {
             } break;
             case AVAssetExportSessionStatusCancelled: {
             } break;
             case AVAssetExportSessionStatusCompleted: {
                 if (resultBlock) {
                     resultBlock(outputFilePath);
                     return;
                 }
             } break;
             default: {
             } break;
         }
         
         if (resultBlock) {
             resultBlock(nil);
         }
         
     }
     ];
}

+ (CGFloat)getMediaDurationWithMediaUrl:(NSString *)mediaUrlStr {
    
    NSURL *mediaUrl = [NSURL URLWithString:mediaUrlStr];
    AVURLAsset *mediaAsset = [[AVURLAsset alloc] initWithURL:mediaUrl options:nil];
    CMTime duration = mediaAsset.duration;
    
    return duration.value / duration.timescale;    
}

+ (NSString *)getMediaFilePath {
    
    return [NSTemporaryDirectory() stringByAppendingPathComponent:MediaFileName];
    
}

@end
