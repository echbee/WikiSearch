//
//  Created by Harpreet Bansal
//

#import <UIKit/UIKit.h>

@interface ResultsTableViewCell : UITableViewCell

@property NSString *title;
@property NSString *subtitle;
@property UIImage *renditionImage;

-(void)startActivity;
-(void)stopActivity;

@end
