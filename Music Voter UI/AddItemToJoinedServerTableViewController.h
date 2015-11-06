//
//  AddItemToJoinedServerTableViewController.h
//  Music Voter UI
//
//  Created by Martoko on 03/11/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@interface AddItemToJoinedServerTableViewController : UITableViewController

@property (nonatomic, weak) id delegate;

@end

@protocol AddItemToJoinedServerTableViewControllerDelegate <NSObject>

- (void)didSelectTrack:(SPTPartialTrack*)track;

@end