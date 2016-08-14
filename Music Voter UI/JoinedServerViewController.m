//
//  JoinedServerViewController2.m
//  Music Voter UI
//
//  Created by Martoko on 08/11/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "JoinedServerViewController.h"

@interface JoinedServerViewController ()

// contentView's vertical bottom constraint, used to alter the contentView's vertical size when ads arrive
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (nonatomic) GADBannerView *bannerView;
@property (nonatomic) BOOL adAvailable;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *trackLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addItemButton;
@property (weak, nonatomic) IBOutlet UIView *nowPlayingView;
@property (weak, nonatomic) IBOutlet UIView *noSongPlayingView;

@end

@implementation JoinedServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Joining...";
    
    // GAD
    _adAvailable = NO;
    _bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
    self.bannerView.delegate = self;
    
    self.bannerView.adUnitID = @"ca-app-pub-6684572586680338/7988188404";
    self.bannerView.rootViewController = self;
    
    GADRequest *request = [GADRequest request];
    request.testDevices = @[ kGADSimulatorID ];
    [self.bannerView loadRequest:request];
    self.bannerView.hidden = NO;
    
    [self.view addSubview:self.bannerView];
    // END GAD
}

//-(void) DEBUG_kill_ad {
//    [self adView:self.bannerView didFailToReceiveAdWithError:nil];
//    
//    [self performSelector:@selector(DEBUG_spawn_ad) withObject:nil afterDelay:5.0];
//}
//
//-(void) DEBUG_spawn_ad {
//    GADRequest *request = [GADRequest request];
//    request.testDevices = @[ kGADSimulatorID ];
//    
//    [self.bannerView loadRequest:request];
//    [self performSelector:@selector(DEBUG_kill_ad) withObject:nil afterDelay:5.0];
//}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self layoutAnimated:NO];
}

- (void)viewDidLayoutSubviews {
    [self layoutAnimated:[UIView areAnimationsEnabled]];
}

- (void)layoutAnimated:(BOOL)animated {
    CGRect contentFrame = self.view.bounds;
    
    // all we need to do is ask the banner for a size that fits into the layout area we are using
    CGSize sizeForBanner = [self.bannerView sizeThatFits:contentFrame.size];
    
    // compute the ad banner frame
    CGRect bannerFrame = self.bannerView.frame;
    if (self.adAvailable) {
        
        // bring the ad into view
        contentFrame.size.height -= sizeForBanner.height;   // shrink down content frame to fit the banner below it
        bannerFrame.origin.y = contentFrame.size.height;
        bannerFrame.size.height = sizeForBanner.height;
        bannerFrame.size.width = sizeForBanner.width;
        
        // if the ad is available and loaded, shrink down the content frame to fit the banner below it,
        // we do this by modifying the vertical bottom constraint constant to equal the banner's height
        //
        NSLayoutConstraint *verticalBottomConstraint = self.bottomConstraint;
        verticalBottomConstraint.constant = sizeForBanner.height;
        [self.view layoutSubviews];
        
    }
    else {
        NSLayoutConstraint *verticalBottomConstraint = self.bottomConstraint;
        verticalBottomConstraint.constant = 0;
        
        // hide the banner off screen further off the bottom
        bannerFrame.origin.y = contentFrame.size.height;
    }
    
    [UIView animateWithDuration:animated ? 0.25 : 0.0 animations:^{
        [self.tableView layoutIfNeeded];
        self.bannerView.frame = bannerFrame;
    }];
}

#pragma mark - AddItemToJoinedServerTableViewController Delegate

- (void)didSelectTrack:(SPTPartialTrack *)track {
    [self.musicVoterConnection sendAddedVoteForTrack:track.uri.absoluteString];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier  isEqualToString: @"JoinedServerToAddItem"]) {
        AddItemToJoinedServerTableViewController* newViewController = [segue destinationViewController];
        newViewController.delegate = self;
        
    }
}

#pragma mark - GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)bannerView {
    //bannerView.hidden = NO;
    
    self.adAvailable = YES;
    [self layoutAnimated:YES];
}
- (void)adView:(GADBannerView *)bannerView
didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"adView:didFailToReceiveAdWithError: %@", error.localizedDescription);
    self.adAvailable = NO;
    [self layoutAnimated:YES];
    
    //bannerView.hidden = YES;
}
- (void)adViewWillPresentScreen:(GADBannerView *)bannerView {
    /*This callback is sent immediately before the user is presented with a full-screen ad UI in response to their touching the sender. At this point, you should pause any animations, timers, or other activities that assume user interaction and save app state, much like on UIApplicationDidEnterBackgroundNotification. Typically, the user simply browses the full-screen ad and dismisses it, generating adViewDidDismissScreen: and returning control to your app. If the banner's action was either Click-to-App-Store or Click-to-iTunes or the user presses Home within the ad, however, your app will be backgrounded and potentially terminated.
     
     In these cases under iOS 4.0+, the next method invoked will be your root view controller's applicationWillResignActive:, followed by adViewWillLeaveApplication:.*/
}
- (void)adViewDidDismissScreen:(GADBannerView *)bannerView {
    /*Sent when the user has exited the sender's full-screen UI.*/
}
- (void)adViewWillDismissScreen:(GADBannerView *)bannerView {
    /*Sent immediately before the sender's full-screen UI is dismissed, restoring your app and the root view controller. At this point, you should restart any foreground activities paused as part of adViewWillPresentScreen:.*/
}
- (void)adViewWillLeaveApplication:(GADBannerView *)bannerView {
    /*Sent just before the app gets backgrounded or terminated as a result of the user touching a Click-to-App-Store or Click-to-iTunes banner. The normal UIApplicationDelegate notifications like applicationDidEnterBackground: arrive immediately before this.
     Do not request an ad in applicationWillEnterForeground:, as the request will be ignored. Place the request in applicationDidBecomeActive: instead.*/
}

@end
