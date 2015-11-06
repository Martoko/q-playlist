//
//  CreatedServerTableViewController.h
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicVoterServer.h"
#import "AddItemToCreatedServerTableViewController.h"

@interface CreatedServerTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, AddItemToCreatedServerTableViewControllerDelegate>

@property MusicVoterServer* musicVoterServer;

@end
