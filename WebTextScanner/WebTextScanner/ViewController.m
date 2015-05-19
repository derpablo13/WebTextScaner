//
//  ViewController.m
//  WebTextScanner
//
//  Created by parak on 4/2/15.
//  Copyright (c) 2015 parak. All rights reserved.
//

#import "ViewController.h"
#import "WTSearchManager.h"
#import "HTMLParser.h"

@interface ViewController () <UITextFieldDelegate, UITextViewDelegate>

@property WTSearchManager *searchManager;
@property IBOutlet UILabel *searchThreadsLabel;
@property IBOutlet UILabel *searchURLsLabel;

@property IBOutlet UITextField *searchURL;
@property IBOutlet UITextView *searchText;
@property IBOutlet UIStepper *searchThreadsStepper;
@property IBOutlet UIStepper *searchURLsStepper;
@property IBOutlet UISwitch *searchTextWithTrimmingSwitcher;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.searchURL.delegate = self;
    self.searchText.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [self.searchText setContentOffset:CGPointZero];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)searchThreadsValueChanged:(id)sender {
    UIStepper *stepper = (UIStepper *)sender;
    self.searchThreadsLabel.text = [NSString stringWithFormat:@"%d", (int)stepper.value];
}

- (IBAction)searchURLsValueChanged:(id)sender {
    UIStepper *stepper = (UIStepper *)sender;
    self.searchURLsLabel.text = [NSString stringWithFormat:@"%d", (int)stepper.value];
}

- (IBAction)startSearching:(id)sender {
    if ([self inputtedTextIsValid]) {
        [self startSearch];
    }
}

- (void)startSearch {
    self.searchManager = [WTSearchManager new];
    
    [self.searchManager searchWebTextForUrl:self.searchURL.text
                     maxConcurrentTaskCount:(NSInteger)self.searchThreadsStepper.value
                                 searchText:self.searchText.text
                          maxSearchUrlCount:(NSInteger)self.searchURLsStepper.value];
    
    //http://code.tutsplus.com/tutorials/networking-with-nsurlsession-part-1--mobile-21394
    
    // @"http://habrahabr.ru/company/stratoplan/blog/254693/"
}

- (BOOL)inputtedTextIsValid {
    if ([self stringIsEmpty:self.searchURL.text]) {
        [self showAletrWithTitle:@"Wrong search data"
                         message:@"Start URL is empty.\nPlease input valid start URL."];
        return NO;
    }
    
    if ([self stringIsEmpty:self.searchText.text]) {
        [self showAletrWithTitle:@"Wrong search data"
                         message:@"Search text is empty.\nPlease input valid search text."];
        return NO;
    }
    
    return YES;
}

- (BOOL)stringIsEmpty:(NSString *)string {
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {//whitespaceAndNewlineCharacterSet
        return YES;
    }
    return NO;
}

- (void)showAletrWithTitle:(NSString *)title
                   message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
}

#pragma mark - Text field delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (range.location == 6 && range.length == 1) {
        return NO;
    }
    
    //NSLog(@"textField.text %@", textField.text);
    //NSLog(@"string %@", string);
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f,
                                                                         0.0f,
                                                                         self.view.window.frame.size.width,
                                                                         44.0f)];
        
        toolBar.items = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                        target:nil
                                                                        action:nil],
                          [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(textViewCancelButtonPressed)]
                          ];
        
        self.searchText.inputAccessoryView = toolBar;
    }
    
    return YES;
}

- (void)textViewCancelButtonPressed {
    [self.searchText endEditing:YES];
}



- (void)testScan {
    NSString *rawString = @"          		Welcome! The      Unicode Consortium enables people around the world to use\n		computers in any language. Our freely-available specifications and data form the foundation\n		for software internationalization in all major operating systems, search engines, applications,\n		and the World Wide Web. An essential part of our mission is to educate and engage academic and scientific\n		communities, and the general public.     ";
    
    NSString *squashedRawString = [rawString stringByReplacingOccurrencesOfString:@"\\s+"
                                                                       withString:@" "
                                                                          options:NSRegularExpressionSearch
                                                                            range:NSMakeRange(0, rawString.length)];
    
    NSString *finalRawString = [squashedRawString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    
    NSString *searchText = @"Welcome! The Unicode Consortium enables people around the world to use computers in any language. Our freely-available specifications and data form the foundation for software internationalization in all major operating systems, search engines, applications, and the World Wide Web. An essential part of our mission is to educate and engage academic and scientific communities, and the general public.";
    
    NSString *squashedSearchText = [searchText stringByReplacingOccurrencesOfString:@"\\s+"
                                                                         withString:@" "
                                                                            options:NSRegularExpressionSearch
                                                                              range:NSMakeRange(0, searchText.length)];
    
    NSString *finalSearchText = [squashedSearchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    
    
    /*
    NSString *foundString;
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:finalRawString];
    BOOL found = [scanner scanString:finalSearchText intoString:&foundString];
    NSLog(@"\n\nscanner.scanLocation %d", scanner.scanLocation);
    NSLog(@"found %d", found);
    NSLog(@"foundString %@", foundString);
     */
    
    BOOL found = [finalRawString rangeOfString:finalSearchText options:NSCaseInsensitiveSearch].location != NSNotFound;
    //BOOL found = [rawString rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound;
    NSLog(@"found %d", found);
}

- (void)searchTest {
    /*
    // Load a web page.
    NSURL *URL = [NSURL URLWithString:@"https://github.com/nolanw/HTMLReader"];
    //NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.HTTPMaximumConnectionsPerHost = 10;
    sessionConfig.timeoutIntervalForResource = 0;
    sessionConfig.timeoutIntervalForRequest = 0;
    
    sessionConfig.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0
                                                           diskCapacity:0
                                                               diskPath:nil];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:nil
                                                     delegateQueue:nil];
    
    for (NSInteger i = 0; i < 100; i++) {
        [[session dataTaskWithURL:URL completionHandler:
          ^(NSData *data, NSURLResponse *response, NSError *error) {
              NSString *contentType = nil;
              if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                  NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
                  contentType = headers[@"Content-Type"];
              }
              
              HTMLDocument *home = [HTMLDocument documentWithData:data
                                                contentTypeHeader:contentType];
              HTMLElement *div = [home firstNodeMatchingSelector:@".repository-description"];
              NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
              NSLog(@"%@", [div.textContent stringByTrimmingCharactersInSet:whitespace]);
              // => A WHATWG-compliant HTML parser in Objective-C.
              
              
              
              // Clearing.
              //home.textContent = nil;
            
              
              
              
              for (HTMLNode *node in home.children) {
                  [node removeFromParentNode];
                  NSLog(@"remove node");
              }
              [home removeFromParentNode];
              
              
              
              
          }] resume];
    }
    */
}

- (void)searchTest2 {
    // Load a web page.
    NSURL *URL = [NSURL URLWithString:@"https://github.com/zootreeves/Objective-C-HMTL-Parser"];
    //NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.HTTPMaximumConnectionsPerHost = 10;
    sessionConfig.timeoutIntervalForResource = 0;
    sessionConfig.timeoutIntervalForRequest = 0;
    
    sessionConfig.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0
                                                           diskCapacity:0
                                                               diskPath:nil];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:nil
                                                     delegateQueue:nil];
    
    for (NSInteger i = 0; i < 1; i++) {
        [[session dataTaskWithURL:URL completionHandler:
          ^(NSData *data, NSURLResponse *response, NSError *error) {
              HTMLParser *parser = [[HTMLParser alloc] initWithData:data error:&error];
              
              if (error) {
                  NSLog(@"Error: %@", error);
                  return;
              }
              
              HTMLNode *bodyNode = [parser body];
              NSLog(@"bodyNode.contents %d", bodyNode.allContents.length);
              
              
              NSArray *linkNodes = [bodyNode findChildTags:@"a"];
              
              for (HTMLNode *linkNode in linkNodes) {
                  NSLog(@"href=\"%@\"", [linkNode getAttributeNamed:@"href"]);
              }
              
              NSLog(@"linkNodes.count %d", linkNodes.count);
              
              /*
              NSArray *spanNodes = [bodyNode findChildTags:@"span"];
              
              for (HTMLNode *spanNode in spanNodes) {
                  if ([[spanNode getAttributeNamed:@"class"] isEqualToString:@"spantext"]) {
                      NSLog(@"%@", [spanNode rawContents]); //Answer to second question
                  }
              }
               */
          }] resume];
    }
}

@end
