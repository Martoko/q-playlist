//
//  JoinedServerViewController2.h
//  Music Voter UI
//
//  Created by Martoko on 08/11/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicVoterConnectionViewController.h"
#import "AddItemToJoinedServerTableViewController.h"
#import <iAd/iAd.h>

@interface JoinedServerViewController : MusicVoterConnectionViewController<AddItemToJoinedServerTableViewControllerDelegate, ADBannerViewDelegate>

@end
