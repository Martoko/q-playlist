//
//  SingleVoteTableViewCell.h
//  Music Voter UI
//
//  Created by Martoko on 23/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VoteTrackTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *voteButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end
