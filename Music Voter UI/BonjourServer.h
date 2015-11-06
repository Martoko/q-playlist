//
//  BonjourServer.h
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>
#import <UIKit/UIKit.h>
#import "Connection.h"
#import "VoteTrack.h"

@interface BonjourServer : NSObject <NSNetServiceDelegate,
ConnectionDelegate>

@property (nonatomic, weak) id delegate;
@property BOOL published;
-(NSString*) getName;

- (id)initWithName: (NSString*) name;
- (void) publish;
@end

@protocol BonjourServerDelegate <NSObject>

-(void)bonjourServerDidPublish;
-(void)connectionEstablished: (Connection*) connection;

@end