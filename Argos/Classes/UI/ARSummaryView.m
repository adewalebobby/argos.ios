//
//  ARSummaryView.m
//  Argos
//
//  Created by Francis Tseng on 2/8/14.
//  Copyright (c) 2014 Argos. All rights reserved.
//

#import "ARSummaryView.h"
#import "Entity.h"

@implementation ARSummaryView

- (id)initWithOrigin:(CGPoint)origin text:(NSString*)summaryText updatedAt:(NSDate*)updatedAt
{
    float paddingX = 16.0;
    float paddingY = 8.0;
    CGRect bounds = [[UIScreen mainScreen] bounds];
    CGRect frame = CGRectMake(origin.x, origin.y, bounds.size.width, 400.0);
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        // Header view with meta and actions.
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, 30.0 + paddingY)];
        
        // Setup time ago
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingX,
                                                               paddingY,
                                                               bounds.size.width - (paddingX*2),
                                                               20.0)];
        _timeLabel.text = [NSDate dateDiff:updatedAt];
        _timeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:10.0];
        _timeLabel.textColor = [UIColor mutedColor];
        [headerView addSubview:_timeLabel];
        
        // Setup action buttons
        UIButton* favoriteButton = [self buttonWithAction:@selector(favorite:) imageNamed:@"favorite"];
        CGRect favoriteFrame = favoriteButton.frame;
        favoriteFrame.origin.x = bounds.size.width - paddingX - favoriteButton.imageView.frame.size.width;
        favoriteFrame.origin.y = paddingY;
        favoriteButton.frame = favoriteFrame;
        [headerView addSubview:favoriteButton];
        
        UIButton* watchButton = [self buttonWithAction:@selector(watch:) imageNamed:@"watch"];
        CGRect watchFrame = watchButton.frame;
        watchFrame.origin.x = favoriteButton.frame.origin.x - paddingX*2;
        watchFrame.origin.y = paddingY;
        watchButton.frame = watchFrame;
        [headerView addSubview:watchButton];
        
        [self addSubview:headerView];
        
        // Setup summary text
        _summaryWebView = [[UIWebView alloc] initWithFrame:CGRectMake(paddingX,
                                                                        _timeLabel.frame.origin.y + _timeLabel.frame.size.height + paddingY*2,
                                                                        bounds.size.width - (paddingX*2),
                                                                        200.0)];
        _summaryWebView.delegate = self;
        [self setText:summaryText withEntities:nil];
        _summaryWebView.scrollView.scrollEnabled = NO;
        _summaryWebView.scrollView.bounces = NO;
        [self addSubview:_summaryWebView];
        
        [self sizeToFit];
    }
    return self;
}

- (void)setText:(NSString*)summaryText withEntities:(NSSet*)entities
{
    // Entities are sorted by length (longest first) so when replacing them in the summary text,
    // the larger names are captured first. Then names are replaced taking into account their spaces.
    // Combined, this avoids situations with nested `a` tags.
    // For instance, "UN Convention" might become "<a href='#'><a href='#'>UN</a> Convention</a>".
    // Instead, " UN Convention" as a whole is captured: "<a href='#'>UN Convention</a>",
    // and then " UN" can't be captured since it has no space on the left anymore.
    NSArray* sortedEntities = [[entities allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber *first = [NSNumber numberWithInt:[[(Entity*)obj1 name] length]];
        NSNumber *second = [NSNumber numberWithInt:[[(Entity*)obj2 name] length]];
        return [first compare:second];
    }];
    
    for (Entity* entity in sortedEntities) {
        summaryText = [summaryText stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@" %@", entity.name] withString:[NSString stringWithFormat:@" <a href='#' onclick='objc(\"%@\");'>%@</a>", entity.entityId, entity.name]];
    }
    
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"SummaryTemplate" ofType:@"html" inDirectory:nil];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    NSString* summaryHtml = [htmlString stringByReplacingOccurrencesOfString:@"{{summary}}" withString:summaryText];
    [_summaryWebView loadHTMLString:summaryHtml baseURL:nil];
}

- (UIButton*)buttonWithAction:(SEL)selector imageNamed:(NSString*)imageName
{
    UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    UIImage* image = [UIImage imageNamed:imageName];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    return button;
}

# pragma mark - Actions

- (void)favorite:(id)sender
{
    NSLog(@"favorited");
    UIButton *button = (UIButton*)sender;
    if (button.tag != 1) {
        [button setImage:[UIImage imageNamed:@"favorited"] forState:UIControlStateNormal];
        [button setTag:1];
    } else {
        [button setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
        [button setTag:0];
    }
}
- (void)watch:(id)sender
{
    NSLog(@"watched");
    UIButton *button = (UIButton*)sender;
    if (button.tag != 1) {
        [button setImage:[UIImage imageNamed:@"watched"] forState:UIControlStateNormal];
        [button setTag:1];
    } else {
        [button setImage:[UIImage imageNamed:@"watch"] forState:UIControlStateNormal];
        [button setTag:0];
    }
}


# pragma mark - UIView

- (CGSize)sizeThatFits:(CGSize)size
{
    //float w = 0;
    float h = 0;
    float padding = 24.0;
    
    for (UIView *v in [self subviews]) {
        //float fw = v.frame.origin.x + v.frame.size.width;
        float fh = v.frame.origin.y + v.frame.size.height;
        //w = MAX(fw, w);
        h = MAX(fh, h);
    }
    return CGSizeMake(self.frame.size.width, h + padding);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Calculate the positioning of subviews.
    float yOffset = NAN;
    for (UIView *v in [self subviews]) {
        CGRect frame = v.frame;
        float oy = frame.origin.y;
        if (isnan(yOffset)) {
            yOffset = oy;
        }
        frame.origin.y = yOffset;
        yOffset += frame.size.height;
        v.frame = frame;
    }
    [self sizeToFit];
    
    // Since this view's size changed,
    // update it's superview's size too.
    [self.superview sizeToFit];
}


# pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    // Resize the UIWebView to fit all content.
    CGRect frame = aWebView.frame;
    frame.size.height = 1;
    aWebView.frame = frame;
    CGSize fittingSize = [aWebView sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    aWebView.frame = frame;
    
    // Disable long touch in the web view.
    [aWebView stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none'; document.body.style.KhtmlUserSelect='none'"];
    
    // Resize the summary view.
    [self sizeToFit];
}

// For calling Objective-C from the UIWebView's Javascript.
- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *requestString = [[request URL] absoluteString];
    if ([requestString hasPrefix:@"objc:"]) {
        
        // Extract the selector name from the URL
        NSArray *components = [requestString componentsSeparatedByString:@":"];
        NSString *entityId = [components objectAtIndex:1];
        
        // Call the given selector
        [_delegate performSelector:@selector(viewEntity:) withObject:entityId];
        
        // Cancel the location change
        return NO;
    }
    
    // Accept this location change
    return YES;
}




@end