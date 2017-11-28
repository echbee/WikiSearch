//
//  Created by Harpreet Bansal
//

#import "ResultsTableViewCell.h"

@interface ResultsTableViewCell()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *renditionImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *renditionActivityIndicator;

@end

@implementation ResultsTableViewCell

-(instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self)
    {
        [self commonInit];
    }
    return self;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self commonInit];
    }
    return self;
}

-(void) commonInit
{
    self.title = self.subtitle = nil;
    self.renditionImage = nil;
    [self stopActivity];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)startActivity
{
    [self.renditionActivityIndicator setHidden:NO];
    [self.renditionActivityIndicator startAnimating];
}

-(void)stopActivity
{
    [self.renditionActivityIndicator setHidden:YES];
    [self.renditionActivityIndicator stopAnimating];
}

#pragma mark PROPERTY SETTERS/GETTERS

-(void) setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

-(NSString*) title
{
    return [self.titleLabel.text copy];
}

-(void) setSubtitle:(NSString *)subtitle
{
    self.subtitleLabel.text = subtitle;
}

-(NSString*) subtitle
{
    return [self.subtitleLabel.text copy];
}

-(void) setRenditionImage:(UIImage *)image
{
    self.renditionImageView.image = image;
    
    if(self.renditionImageView.image != nil)
        [self stopActivity];
}

-(UIImage*) renditionImage
{
    return self.renditionImageView.image;
}

@end
