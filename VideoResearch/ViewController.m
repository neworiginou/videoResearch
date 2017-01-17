//
//  ViewController.m
//  VideoResearch
//
//  Created by ios on 2016/10/22.
//  Copyright © 2016年 ios. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import <AssetsLibrary/ALAssetsLibrary.h>

#import "MediaManager.h"


@interface ViewController ()

@property (nonatomic, strong)   GPUImageView           *resultImageView;
@property (nonatomic, strong)  GPUImageMovie           *movieSource;
@property (nonatomic, strong)  GPUImageMovieWriter     *movieWriter;

@property (nonatomic, strong)  GPUImageFilter          *filter;

@property (nonatomic, strong)  GPUImageUIElement       *uiElement;
@property (nonatomic, strong)  GPUImageFilter          *progressFilter;

@property (nonatomic, strong)  UIView                  *contentView;
@property (nonatomic, strong)  UIImageView             *gifView;



@property (nonatomic, strong)  UIImageView             *logoView;
@property (nonatomic, strong)  UIView                  *authorView;

@property (nonatomic, strong)   AVAudioPlayer           *audioPlayer;
@property (nonatomic, strong)   AVAudioPlayer           *audioPlayer2;

@end

@implementation ViewController
{

    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor blueColor];
    [button setTitle:@"音乐合成" forState:UIControlStateNormal];
    button.frame = CGRectMake(10, 30, 80, 40);
    [self.view addSubview:button];
    [button addTarget:self action:@selector(musicButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width);
    frame.origin.y = (self.view.frame.size.height - self.view.frame.size.width) * 0.5;
    GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:frame];
    [self.view addSubview:filterView];
    _resultImageView = filterView;
    
    _filter = [[GPUImageNormalBlendFilter alloc] init];
//     [(GPUImageAlphaBlendFilter *)_filter setMix:1.0];
    
    _contentView = [[UIView alloc] initWithFrame:_resultImageView.bounds];
    _contentView.layer.contentsScale = 2.0;
    _gifView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 240, 120)];
    [_contentView addSubview:_gifView];
    _gifView.center = _contentView.center;
//    _gifView.transform = CGAffineTransformMakeScale(1.5, 1.5);
//    _gifView.transform = CGAffineTransformScale(_gifView.transform, -1.0, 1.0);
    
    _authorView = [[UIView alloc] initWithFrame:_contentView.bounds];

    _authorView.backgroundColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.5];
    UIImageView *tailView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    [_authorView addSubview:tailView];
    tailView.center = _authorView.center;
    _authorView.alpha = 0.0;
    [_contentView addSubview:_authorView];
    
    _logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    _logoView.frame = CGRectMake(_contentView.frame.size.width - _logoView.frame.size.width, 0, _logoView.frame.size.width, _logoView.frame.size.height);
    [_contentView addSubview:_logoView];

    _uiElement = [[GPUImageUIElement alloc] initWithView:_contentView];

    NSString *zipaiPath = [[NSBundle mainBundle] pathForResource:@"zipaiconfig.json" ofType:nil];
    NSData *confitData = [NSData dataWithContentsOfFile:zipaiPath];
    
    NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:confitData
                                                          options:kNilOptions
                                                            error:nil];
    
    NSString *imageImage = dict[@"name"];
    NSArray *frameArray = dict[@"frames"];
    NSMutableDictionary *timeImageDict = [NSMutableDictionary dictionaryWithCapacity:[frameArray count]];
    for (NSDictionary *dict in frameArray) {
        NSNumber * time = dict[@"time"];
        NSNumber * imgIndex = dict[@"pic"];
        timeImageDict[time] = imgIndex;
    }
    
    // mv1
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"IMG_0027" withExtension:@"MP4"];
    NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"adidasneo" withExtension:@"mp3"];
    NSURL *audioURL2 = [[NSBundle mainBundle] URLForResource:@"audio" withExtension:@"mp3"];

    
//    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL2 error:nil];
//    [_audioPlayer play];
//    _audioPlayer.numberOfLoops = NSIntegerMax;
//    _audioPlayer.volume = 0.1;
//
//    _audioPlayer2 = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL2 error:nil];
//    [_audioPlayer2 play];
//    _audioPlayer2.volume = 0.5;
//    _audioPlayer2.numberOfLoops = NSIntegerMax;
    
    _movieSource = [[GPUImageMovie alloc] initWithURL:sampleURL];
    //    movieFile.runBenchmark = YES;
    _movieSource.playAtActualSpeed = YES;
    _movieSource.shouldRepeat = YES;
    

    
//    _progressFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"filter1"];
    _progressFilter = [[GPUImageFilter alloc] init];
    [_movieSource addTarget:_progressFilter];
    
    __weak typeof(self) weakSelf = self;
    [_progressFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        
        CGFloat fSec = (CMTimeGetSeconds(time));
        
        NSLog(@"=======\ntime: %.2f\n", fSec);
        if (fSec > 5) {
            _authorView.alpha = 1.0;
        } else {
            _authorView.alpha = 0.0;
        }
        
        fSec -= 5.0;
        long sec = floor(fSec * 10);
        long imageIndex = [timeImageDict[@(sec)] longValue];
        NSString *name = [NSString stringWithFormat:@"%@%ld.png", imageImage, imageIndex];
        weakSelf.gifView.image = [UIImage imageNamed:name];
        
        [weakSelf.uiElement updateWithTimestamp:time];
    }];
    
    // 响应链
    [_progressFilter addTarget:_filter];
    [_uiElement addTarget:_filter];
    
    // 显示到界面
    [_filter addTarget:_resultImageView];
    [_movieSource startProcessing];
    

    //写文件
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
//    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480, 480)];
//    _movieWriter.shouldPassthroughAudio = NO;
//    _movieWriter.encodingLiveVideo = NO;
    
    if (_movieWriter) {
        [_filter addTarget:_movieWriter];
    }
    
    [_movieWriter startRecording];
    
    NSLog(@"setCompletionBlock begin");
    
    [_movieWriter setCompletionBlock:^{
        
        NSLog(@"setCompletionBlock finished");
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.filter removeTarget:strongSelf.movieWriter];
        [strongSelf.movieWriter finishRecording];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToMovie))
        {
            [library writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     if (error) {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil
                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     } else {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil
                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     }
                 });
             }];
        }
        else {
            NSLog(@"error mssg)");
        }
    }];    
}


- (void)musicButtonTouched:(id)sender
{
    [_audioPlayer stop];
    
    NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"adidasneo" withExtension:@"mp3"];
    NSURL *audioURL2 = [[NSBundle mainBundle] URLForResource:@"sound.wav" withExtension:nil];
    NSURL *audioURL3 = [[NSBundle mainBundle] URLForResource:@"sound2.wav" withExtension:nil];


    [MediaManager meargeAudioWidthUrlArray:@[audioURL, audioURL2, audioURL3] resultBlock:^(NSString *filePath) {
       
        NSLog(@"%@", filePath);
        
        NSString *outputFilePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/mergeAudio.mp4"];
        NSURL   *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
        

        _audioPlayer2 = [[AVAudioPlayer alloc] initWithContentsOfURL:outputFileUrl error:nil];
        [_audioPlayer2 play];
        _audioPlayer2.volume = 0.5;
        _audioPlayer2.numberOfLoops = NSIntegerMax;
        [_audioPlayer2 play];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
