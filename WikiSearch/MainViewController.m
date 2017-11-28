//
//  Created by Harpreet Bansal
//

#import "MainViewController.h"
#import "WikiResultModel.h"
#import "ResultsTableViewCell.h"
#import "WikiNetworkLayer.h"
#import "DetailViewController.h"

@interface MainViewController () <UISearchBarDelegate,UITableViewDelegate, UITableViewDataSource>

@property WikiResultModel *resultModel;

@property NSUInteger queryRequestId;

@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic,weak) UITableView *resultsTableView;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UISearchBar *wikiSearchBar = [[UISearchBar alloc] init];
    [self.view addSubview:wikiSearchBar];
    self.searchBar = wikiSearchBar;
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraints:@[
                                [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
                                [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
                                [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:20],
                                [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:44],
                                ]];
    self.searchBar.placeholder = @"I want to learn about...";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.delegate = self;
    
    UITableView *tableView = [[UITableView alloc] init];
    [self.view addSubview:tableView];
    self.resultsTableView = tableView;
    self.resultsTableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraints:@[
                                [NSLayoutConstraint constraintWithItem:self.resultsTableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
                                [NSLayoutConstraint constraintWithItem:self.resultsTableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0],
                                [NSLayoutConstraint constraintWithItem:self.resultsTableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.searchBar attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
                                [NSLayoutConstraint constraintWithItem:self.resultsTableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]
                                ]];
    
    self.resultsTableView.dataSource = self;
    self.resultsTableView.delegate = self;
    [self.resultsTableView registerNib:[UINib nibWithNibName:@"ResultsTableViewCell" bundle:nil] forCellReuseIdentifier:@"ResultsTableViewCell"];
    
    //initialize model
    self.resultModel = [[WikiResultModel alloc] init];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    for(NSUInteger resultIndex = 0 ; resultIndex < [self.resultModel count] ; ++resultIndex)
    {
        WikiResult *aResult = [self.resultModel resultAtIndex:resultIndex];
        aResult.renditionImage = nil;
    }
}

-(NSArray<WikiResult*> *)parseQueryResponse:(NSData*)queryResponse
{
    NSError *err;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:queryResponse options:kNilOptions error:&err];
    if(err != nil)
    {
        NSLog(@"Error parsing query response:%@\n",err.localizedDescription);
        return nil;
    }
    
    NSMutableArray<WikiResult *> *parsedResults = [NSMutableArray array];
    NSDictionary *pagesDict = jsonDict[@"query"][@"pages"];
    for(NSString *pageNumber in pagesDict.allKeys)
    {
        NSDictionary *aPage = pagesDict[pageNumber];
        NSURL *aPageRenditionURL = nil;
        if([aPage objectForKey:@"thumbnail"])
        {
            aPageRenditionURL = [NSURL URLWithString:aPage[@"thumbnail"][@"source"]];
        }
        
        WikiResult *aResult = [[WikiResult alloc] initWithTitle:aPage[@"title"] subtitle:aPage[@"extract"] renditionURL:aPageRenditionURL fullURL:[NSURL URLWithString:aPage[@"fullurl"]]];
        [parsedResults addObject:aResult];
    }
    
    return parsedResults;
}

-(NSURL*) createURLForQuery:(NSString*)query
{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:@"https://en.wikipedia.org/w/api.php"];
    
    urlComponents.queryItems = @[[NSURLQueryItem queryItemWithName:@"format" value:@"json"],
                                 [NSURLQueryItem queryItemWithName:@"format" value:@"json"],
                                 [NSURLQueryItem queryItemWithName:@"action" value:@"query"],
                                 [NSURLQueryItem queryItemWithName:@"generator" value:@"search"],
                                 [NSURLQueryItem queryItemWithName:@"gsrnamespace" value:@"0"],
                                 [NSURLQueryItem queryItemWithName:@"gsrsearch" value:query],
                                 [NSURLQueryItem queryItemWithName:@"gsrlimit" value:@"10"],
                                 [NSURLQueryItem queryItemWithName:@"prop" value:@"pageimages|extracts|info"],
                                 [NSURLQueryItem queryItemWithName:@"inprop" value:@"url"],
                                 [NSURLQueryItem queryItemWithName:@"pilimit" value:@"max"],
                                 [NSURLQueryItem queryItemWithName:@"exintro" value:nil],
                                 [NSURLQueryItem queryItemWithName:@"explaintext" value:nil],
                                 [NSURLQueryItem queryItemWithName:@"exsentences" value:@"1"],
                                 [NSURLQueryItem queryItemWithName:@"exlimit" value:@"max"]];
    
    return urlComponents.URL;
}

-(void) processQuery:(NSString*)query
{
    
    NSURL *requestURL = [self createURLForQuery:query];
    [[WikiNetworkLayer sharedInstance] cancelRequest:self.queryRequestId];
    self.queryRequestId = [[WikiNetworkLayer sharedInstance] fetchUrlRequest:requestURL onCompletion:^(NSData *data) {
        NSArray<WikiResult*> *results = [self parseQueryResponse:data];
        [self.resultModel reset];
        [self.resultModel addResults:results];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.resultsTableView reloadData];
        });
    } onError:^(NSError *err, NSUInteger httpCode) {
        if(err != nil)
        {
            NSLog(@"Error:%@, httpCode:%lu\n",err.localizedDescription,httpCode);
            return;
        }
    }];
}

#pragma mark - Table view data source methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.resultModel count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *subtitleText = [self.resultModel resultAtIndex:indexPath.row].subtitle;
    CGSize size = [subtitleText sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:CGSizeMake(tableView.frame.size.width - 55, 1000.0f)];
    return size.height + 50;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ResultsTableViewCell *aCell = [tableView dequeueReusableCellWithIdentifier:@"ResultsTableViewCell"];
    
    //clean up the cell
    aCell.renditionImage = nil;
    aCell.title = nil;
    aCell.subtitle = nil;
    
    WikiResult *aResult = [self.resultModel resultAtIndex:indexPath.row];
    aCell.title = aResult.title;
    aCell.subtitle = aResult.subtitle;
    
    if(aResult.renditionImage == nil)
    {
        [aCell startActivity];
        [[WikiNetworkLayer sharedInstance] fetchUrlRequest:aResult.renditionURL onCompletion:^(NSData *data) {
            
            UIImage *cellRenditionImage = [UIImage imageWithData:data];
            if(cellRenditionImage)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.resultModel resultAtIndex:indexPath.row].renditionImage = cellRenditionImage;
                    [self.resultsTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                });
            }
            
        } onError:^(NSError *err, NSUInteger httpCode) {
            NSLog(@"RenditionError:%@, httpCode:%lu\n",err.localizedDescription,httpCode);
            dispatch_async(dispatch_get_main_queue(), ^{
                ResultsTableViewCell *blockCell = [tableView cellForRowAtIndexPath:indexPath];
                [blockCell stopActivity];
            });
        }];
    }
    else
    {
        aCell.renditionImage = aResult.renditionImage;
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    }
    
    return aCell;
}

#pragma mark - Tableview delegate methods

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DetailViewController *detailVC = [[DetailViewController alloc] init];
    detailVC.result = [self.resultModel resultAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:detailVC animated:YES];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *resultHeaderView = [[UIView alloc] initWithFrame:CGRectMake(tableView.frame.origin.x, tableView.frame.origin.y, tableView.frame.size.width, 50)];
    resultHeaderView.backgroundColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1];
    
    UILabel *labelView = [[UILabel alloc] init];
    [labelView setText:@"Results"];
    labelView.translatesAutoresizingMaskIntoConstraints = NO;
    [labelView sizeToFit];
    
    [resultHeaderView addSubview:labelView];
    [resultHeaderView addConstraints:@[
                                       [NSLayoutConstraint constraintWithItem:labelView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:resultHeaderView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
                                       [NSLayoutConstraint constraintWithItem:labelView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:resultHeaderView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
                                       [NSLayoutConstraint constraintWithItem:resultHeaderView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:0 constant:50]]];
    
    return resultHeaderView;
}

#pragma mark - Searchbar delegate methods
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self processQuery:searchBar.text];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self processQuery:searchText];
}

@end
