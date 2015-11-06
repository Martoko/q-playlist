//
//  BonjourBrowser.h
//  Music Voter UI
//
//  Created by Martoko on 22/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BonjourBrowser : NSObject <NSNetServiceBrowserDelegate>

@property (nonatomic, weak) id delegate;
@property NSMutableArray* foundServers;

@end


@protocol BonjourBrowserDelegate <NSObject>

-(void) serverlistChanged;

@end