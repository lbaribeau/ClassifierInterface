@import "../Models/Classifier.j"

@implementation ClassifierController : CPObject
{
    @outlet CPWindow openClassifiersWindow;
    @outlet CPButton cancelOpenButton;
    @outlet CPButton openButton;
    @outlet LoadClassifiersDelegate loadClassifiersDelegate;
    @outlet OpenClassifierDelegate  openClassifierDelegate;
    @outlet CPArrayController   classifierArrayController;
    @outlet CPWindow newClassifierWindow;
    @outlet CPButton cancelNewButton;
    @outlet CPButton createClassifierButton;
}
- (void)awakeFromCib
// applicationDidFinishLaunching didn't get called
{
    //[cancelOpenButton setAction:@selector(closeOpenWindow:)];
    [cancelOpenButton setAction:@selector(close)];
    [cancelOpenButton setTarget:openClassifiersWindow];
    [openButton setAction:@selector(openClassifier:)];
    [openButton setTarget:self];
    [cancelNewButton setAction:@selector(close)];
    [cancelNewButton setTarget:newClassifierWindow];
}
//- (@action)newClassifier:(id)aSender
//{
//    var classifier = [[Classifier alloc] init];
//    [projectArrayController addObject:project];
//    [project ensureCreated];    // One-shot Ratatosk call to update the server side.
                                // (you could schedule it if you wanted but it's simpler
                                // to do it in one line if you can.)
//}
- (void)fetchClassifiers
{
    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:'/classifiers/'
                    delegate:loadClassifiersDelegate
                    message:"Loading classifier list"];
}
- (@action)openClassifier:(id)aSender
{
    // Read what is selected and get the glyphs of the corresponding
    // classifier.
    var openClassifier = [[classifierArrayController selectedObjects] objectAtIndex:0];
    [openClassifiersWindow close];

    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:[openClassifier pk]
                    delegate:openClassifierDelegate
                    message:@"loading a single classifier"];

    // TODO: make this function available by double clicking in the open window
}
@end


@implementation LoadClassifiersDelegate : CPObject
{
    @outlet CPArrayController classifierArrayController;
}

- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    var classifiers = [Classifier objectsFromJson:[anAction result]];
    [classifierArrayController addObjects:classifiers];
        // I get a warning for the previous line, not sure why...
        // ends up in CPURLConnection.j
}
@end


@implementation OpenClassifierDelegate : CPObject
{
    Classifier      theClassifier;
    CPArray         itemList;
    @outlet         CPArrayController       classifierGlyphArrayController;
    //@outlet         CPTableView             classifierGlyphTableView;
    @outlet CPCollectionView cv;
}


- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    theClassifier = [[Classifier alloc] initWithJson:[anAction result]];

    console.log("THE CLASSIFIER!");
    console.log(theClassifier);

    //[classifierGlyphArrayController bind:@"contentArray"
    //                                toObject:theClassifier
    //                                withKeyPath:@"glyphs"
    //                                options:nil];

    // If I didn't want to do the link in XCode...
    //[classifierGlyphTableView bind:@"content"
    //                          toObject:classifierGlyphArrayController
    //                          withKeyPath:@""]

/*
    console.log("CollectionView:");
    console.log(cv);
    console.log("Image data");
    console.log([cv itemPrototype]);
    console.log([[cv itemPrototype] view]);
    console.log([[[cv itemPrototype] view] image]);  // good selector, returns null
    // console.log([[[cv itemPrototype] view] representedObject]);  bad selector
    //console.log([[[cv itemPrototype] view] data]);  // No CPImageView data
    // console.log([[[cv itemPrototype] view] view]);  // No CPImageView view
    console.log([[[[cv itemPrototype] view] image] data]);  // null null
*/
    // Try copying Brian... forget about the XCode way
    //[cv setContent:[theClassifier glyphs]];  // This doesn't change much, content is already set well.
    // Try making a copy of the glyphs

    itemList = [];

    //Prepare CPCollectionView
    [cv setAutoresizingMask:CPViewWidthSizable];
    [cv setMinItemSize:CGSizeMake(100, 100)];
    [cv setMaxItemSize:CGSizeMake(100, 100)];
    [cv setDelegate:self];
    [cv setSelectable:YES];

    var itemPrototype = [[CPCollectionViewItem alloc] init];
    [itemPrototype setView:[[PhotoView alloc] initWithFrame:CGRectMakeZero()]];
    [cv setItemPrototype:itemPrototype];


    var theClassifierGlyphs = [theClassifier glyphs];
    for (var i = 0; i < theClassifierGlyphs.length; i++)
    {
        var glyphImageData = [theClassifierGlyphs[i] pngData];
        var glyphImage = [[CPImage alloc] initWithData:glyphImageData];
        itemList[i] = glyphImage;
        // itemList[i] = [[CPImage alloc] initWithData:[[theClassifier glyphs][i] pngData]];
    }
    //console.log("out");
    [cv setContent:itemList];
    console.log(cv);

    /*
    var myglyphs = [[theClassifier glyphs] copy];
    [cv setContent:myglyphs];
    console.log(cv);

    var item = [cv itemPrototype];
    // var myview = [item view];
    // var myimage = [myview image];

    // var myitemprototype = [[CPCollectionViewItem alloc] init];

    [item setView:[[PhotoView alloc] initWithFrame:CGRectMakeZero()]];;
        // Since I'm making a View here I can delete the view from Xcode.
        // However I'll keep the item prototype initialization in XCode for now.
    // [cv setItemPrototype:myitemprototype];
*/



}

@end

@implementation PhotoView : CPImageView
{
    CPImageView _imageView;
}

- (void)setSelected:(BOOL)isSelected
{
    [self setBackgroundColor:isSelected ? [CPColor grayColor] : nil];
}

- (void)setRepresentedObject:(id)anObject
{
    console.log("Yay setRepresented is getting called with...");
    console.log(anObject);
    if (!_imageView)
    {
        var frame = CGRectInset([self bounds], 5.0, 5.0);

        _imageView = [[CPImageView alloc] initWithFrame:frame];

        [_imageView setImageScaling:CPScaleProportionally];
        [_imageView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [self addSubview:_imageView];
    }

    [_imageView setImage:anObject];
}

@end
