//
//  CreateServerTableViewController.h
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CreatedServerTableViewController.h"
#import "MusicVoterServer.h"
#import "SpotifyAuthenticator.h"

@interface CreateServerTableViewController : UITableViewController <SpotifyAuthenticatorDelegate>
@property (weak, nonatomic) IBOutlet UITextField *partyName;

@end
