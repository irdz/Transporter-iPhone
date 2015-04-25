//
// LinesVC.m
// kronos
//
// Created by Ljuba Miljkovic on 3/23/10.
// Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BartStopDetails.h"
#import "DirectionsVC.h"
#import "LinesVC.h"
#import "StopsTVC.h"
#import "acTransitDelegate.h"
#import "bartDelegate.h"
#import "kronosAppDelegate.h"
#import "sfMuniDelegate.h"

@interface LinesVC ()

@property (nonatomic, strong) acTransitDelegate *acDelegate;
@property (nonatomic, strong) sfMuniDelegate *muniDelegate;
@property (nonatomic, strong) bartDelegate *bartDelegate;

@end

@implementation LinesVC

@synthesize acDelegate, muniDelegate, bartDelegate;
@synthesize segmentedControl, tableView, transitDelegate, locationManager;

- (void) viewDidLoad {  

	// tableViewSettings
	self.tableView.showsVerticalScrollIndicator = NO;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

	self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"SF MUNI", @"BART", @"AC Transit"]];
	self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	[self.segmentedControl addTarget:self action:@selector(tapAgency) forControlEvents:UIControlEventValueChanged];

    
	[self.segmentedControl setWidth:100.0 forSegmentAtIndex:0];
	[self.segmentedControl setWidth:98.0 forSegmentAtIndex:1];
	[self.segmentedControl setWidth:102.0 forSegmentAtIndex:2];
    self.segmentedControl.bounds = CGRectMake(0, 0, 302.0, self.segmentedControl.frame.size.height);
    
    //[self.segmentedControl setDividerImage:[UIImage imageNamed:@"seg-divider.png"] forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    //[self.segmentedControl setDividerImage:[UIImage imageNamed:@"seg-divider.png"] forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    //[self.segmentedControl setDividerImage:[UIImage imageNamed:@"seg-divider.png"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    

	self.navigationItem.titleView = self.segmentedControl;

	// setup core location and fetch locations while you're on this screen (for use later)
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;

	// setup notification observing for when a user taps on a route (for ac transit and muni) or station (for bart)
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(loadNextViewController:) name:@"routeSelected" object:nil];
	[notificationCenter addObserver:self selector:@selector(loadNextViewController:) name:@"stopSelected" object:nil];
	[notificationCenter addObserver:self selector:@selector(reloadSection0:) name:@"reloadSection0" object:nil];

	// sets the initial agency data depending on the segmented selected last
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	self.segmentedControl.selectedSegmentIndex = [userDefaults integerForKey:@"linesSegmentedControlIndex"];

    //BACKGROUND IMAGE
    UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    background.frame = self.tableView.frame;
    [self.view insertSubview:background atIndex:0];
    
    self.muniDelegate = [[sfMuniDelegate alloc] initWithAgency:[self fetchAgencyData:@"sf-muni"]];
    self.acDelegate = [[acTransitDelegate alloc] initWithAgency:[self fetchAgencyData:@"actransit"]];
    self.bartDelegate = [[bartDelegate alloc] initWithAgency:[self fetchAgencyData:@"bart"]];
    
	[self tapAgency];
}

// respond to a notification that the table needs reloading
- (void) reloadSection0:(NSNotification *)note {

	// only reload the section if bart is selected
	if (self.segmentedControl.selectedSegmentIndex == 1)	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

// respond to a notification that a (for ac transit and muni) or station (for bart) was tapped
- (void) loadNextViewController:(NSNotification *)note {

	// if an actransit/muni line was selected
	if ([note.name  isEqual: @"routeSelected"]) {

		self.navigationItem.title = @"Lines";

		Route *route = (Route *)[note.object selectedItem];

		DirectionsVC *directionsTableViewController = [[DirectionsVC alloc] init];
		directionsTableViewController.route = route;

		[self.navigationController pushViewController:directionsTableViewController animated:YES];


	} else if ([note.name  isEqual: @"stopSelected"]) {

		self.navigationItem.title = @"Stops";

		Stop *stop = (Stop *)note.object;

		BartStopDetails *bartStopDetailsVC = [[BartStopDetails alloc] initWithStop:stop];
        
		[self.navigationController pushViewController:bartStopDetailsVC animated:YES];

	}
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.locationManager startUpdatingLocation];
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[self.locationManager stopUpdatingLocation];
}

// responds to the tap of the agency segmented control and loads the appropriate agency data
- (void) tapAgency {

	// muni
	if (self.segmentedControl.selectedSegmentIndex == 0) {

        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Lines" style:UIBarButtonItemStylePlain target:nil action:nil];

        
		[self.segmentedControl setImage:[UIImage imageNamed:@"seg-muni-selected.png"] forSegmentAtIndex:0];
		[self.segmentedControl setImage:[UIImage imageNamed:@"seg-bart-deselected.png"] forSegmentAtIndex:1];
		[self.segmentedControl setImage:[UIImage imageNamed:@"seg-actransit-deselected.png"] forSegmentAtIndex:2];
        
        self.locationManager.delegate = nil;
		self.transitDelegate = self.muniDelegate;
        
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.tableView.backgroundColor = [UIColor clearColor];
	}
	// bart
	else if (self.segmentedControl.selectedSegmentIndex == 1) {

        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Stops" style:UIBarButtonItemStylePlain target:nil action:nil];

        
		[self.segmentedControl setImage:[UIImage imageNamed:@"seg-muni-deselected.png"] forSegmentAtIndex:0];
		[self.segmentedControl setImage:[UIImage imageNamed:@"seg-bart-selected.png"] forSegmentAtIndex:1];
		[self.segmentedControl setImage:[UIImage imageNamed:@"seg-actransit-deselected.png"] forSegmentAtIndex:2];
        
		self.transitDelegate = self.bartDelegate;
		self.locationManager.delegate = self.transitDelegate;

		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
		self.tableView.backgroundColor = [UIColor whiteColor];

	}
	// ac transit
	else {
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Lines" style:UIBarButtonItemStylePlain target:nil action:nil];

        
		[self.segmentedControl setImage:[UIImage imageNamed:@"seg-muni-deselected.png"] forSegmentAtIndex:0];
		[self.segmentedControl setImage:[UIImage imageNamed:@"seg-bart-deselected.png"] forSegmentAtIndex:1];
		[self.segmentedControl setImage:[UIImage imageNamed:@"seg-actransit-selected.png"] forSegmentAtIndex:2];
        
        self.locationManager.delegate = nil;
		self.transitDelegate = self.acDelegate;

		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.tableView.backgroundColor = [UIColor clearColor];
	}
    
    self.transitDelegate.parentViewController = self;
    
	// remember which agency is selected, so we can reload it next time
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:self.segmentedControl.selectedSegmentIndex forKey:@"linesSegmentedControlIndex"];

	self.tableView.dataSource = self.transitDelegate;
	self.tableView.delegate = self.transitDelegate;

	[self.tableView reloadData];

	NSIndexPath *topPath = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView scrollToRowAtIndexPath:topPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
}

// retreives an agency's data form core data and returns the Agency object
- (Agency *) fetchAgencyData:(NSString *)agency {

	// get the managedObjectContext from the appDelegate
	kronosAppDelegate *appDelegate = (kronosAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *managedObjectContext = appDelegate.managedObjectContext;

	// Fetch all the agencies from the Core Data store
	NSFetchRequest *request = [[NSFetchRequest alloc] init];

	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Agency" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"shortTitle=%@", agency];
	[request setPredicate:predicate];

	// Receive the results
	NSError *error;
	NSMutableArray *agencies = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];

	if (agencies == nil) {
		return(nil);
	}

	Agency *fetchedAgency = [agencies objectAtIndex:0];

	return(fetchedAgency);
}

- (void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}

- (void) viewDidUnload {
	// Release any retained subviews of the main view.
    
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
	self.tableView = nil;
    
    self.transitDelegate = nil;
    self.locationManager.delegate = nil;
}

- (void) dealloc {

	// unregister the notification from the favorites delegates
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
    
    self.transitDelegate = nil;
    
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    
    self.locationManager.delegate = nil;
}

@end
