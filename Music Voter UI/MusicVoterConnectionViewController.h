//
//  MusicVoterConnectionViewController.h
//  Music Voter UI
//
//  Created by Martoko on 08/11/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicVoterConnectionProtocol.h"
#import "Connection.h"
#import "VoteTrackTableViewCell.h"

@interface MusicVoterConnectionViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, MusicVoterConnectionDelegate>

@property id<ConnectionDelegate, MusicVoterConnection> musicVoterConnection;

@end
