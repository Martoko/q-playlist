//
//  JoinedServerTableViewController.h
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SingleVoteTableViewCell.h"
#import "ServerConnection.h"
#import "AddItemToJoinedServerTableViewController.h"

@interface JoinedServerTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ServerConnectionDelegate, AddItemToJoinedServerTableViewControllerDelegate>

@property ServerConnection* serverConnection;

@end
