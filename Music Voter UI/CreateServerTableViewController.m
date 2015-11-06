//
//  CreateServerTableViewController.m
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "CreateServerTableViewController.h"

@interface CreateServerTableViewController () <UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UISwitch *allowSameTrackNameSwitch;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spotifyLoadIndicator;
@property SpotifyAuthenticator* spotifyAuthenticator;
@property BOOL loggedIn;
@property SPTUser* user;

-(void) hideSpotifyLoadIndicator;
-(void) showSpotifyLoadIndicator;
-(BOOL) isDataOK;

@end

@implementation CreateServerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString* partyNameDefault = [[[NSArray alloc] initWithObjects:[UIDevice currentDevice].name, @"'s party", nil] componentsJoinedByString:@""];
    self.partyName.placeholder = partyNameDefault;
    self.spotifyAuthenticator = [[SpotifyAuthenticator alloc] initWithViewController:self];
    self.spotifyAuthenticator.delegate = self;
    self.loggedIn = NO;
    self.tableView.delegate = self;
    
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    
    [self hideSpotifyLoadIndicator];
    [self.spotifyAuthenticator restoreOldSessionIfValidOtherwiseClearIt];
    self.user = nil;
}

- (void)dealloc
{
    self.spotifyAuthenticator.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row == 1) {
        [self loginButtonPressed:nil];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (IBAction)loginButtonPressed:(id)sender {
    if (self.loggedIn) {
        [self.spotifyAuthenticator logout];
        
        self.usernameLabel.text = @"Logged out";
        [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
        self.loggedIn = NO;
    } else {
        [self.spotifyAuthenticator displayLoginOverlay];
    }
}

#pragma mark - SpotifyAuthenticatorDelegate

- (void)spotifyAuthenticatorStartedLoading: (SpotifyAuthenticator*)spotifyAuthenticator; {
    [self showSpotifyLoadIndicator];
}

-(void) showSpotifyLoadIndicator {
    [self.spotifyLoadIndicator startAnimating];
    self.loginButton.enabled = NO;
    self.usernameLabel.hidden = YES;
}

-(void) hideSpotifyLoadIndicator {
    [self.spotifyLoadIndicator stopAnimating];
    self.loginButton.enabled = YES;
    self.usernameLabel.hidden = NO;
}

- (void)spotifyAuthenticator: (SpotifyAuthenticator*)spotifyAuthenticator loggedInWithSession: (SPTSession*)session andUser: (SPTUser*)user {
    self.user = user;
    
    if (user.displayName != nil) {
        self.usernameLabel.text = user.displayName;
    } else {
        self.usernameLabel.text = user.canonicalUserName;
    }
    
    [self.loginButton setTitle:@"Logout" forState:UIControlStateNormal];
    self.loggedIn = YES;
    [self hideSpotifyLoadIndicator];
    
    [self isDataOK];
}

- (void)spotifyAuthenticator: (SpotifyAuthenticator*)spotifyAuthenticator failedToLoginWithError: (NSError *)error {
    self.usernameLabel.text = @"Logged out";
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    self.loggedIn = NO;
    
    NSString* message = [NSString stringWithFormat:@"The following error occured while logging in: %@", error.localizedDescription];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message: message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"CreateServerToCreatedServer"]) {
        return [self isDataOK];
    }
    
    return YES;
}

- (BOOL)isDataOK {
    if (self.loggedIn == NO) {
        self.usernameLabel.superview.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
        return NO;
    }
    
    if (self.user == nil) {
        assert(NO);
        return NO;
    }
    
    if (self.user.product != SPTProductPremium) {
        self.usernameLabel.superview.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
        return NO;
    }
    
    self.usernameLabel.superview.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    
    return YES;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier  isEqualToString: @"CreateServerToCreatedServer"]) {
        NSString* name = self.partyName.text;
        if ([name isEqualToString:@""]) {
            name = self.partyName.placeholder;
        }

        MusicVoterServer* musicVoterServer = [[MusicVoterServer alloc] initWithName:name];
        
        musicVoterServer.allowSameSongName = self.allowSameTrackNameSwitch.on;
        
        CreatedServerTableViewController* createdServerViewController = [segue destinationViewController];
        [createdServerViewController setMusicVoterServer:musicVoterServer];
    }
}

@end
