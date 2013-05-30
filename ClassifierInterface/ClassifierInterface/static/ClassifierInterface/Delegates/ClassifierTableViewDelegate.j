@import "../Views/PhotoView.j"
@import "../Views/ViewWithObjectValue.j"
@import "../Models/SymbolCollection.j"
@import "../Models/Classifier.j"

@implementation ClassifierTableViewDelegate : CPObject
{
    @outlet CPArrayController symbolCollectionArrayController;
    CPMutableArray collectionViews @accessors;
    CPArray cvArrayControllers @accessors;
    int headerLabelHeight @accessors;
    int photoViewInset @accessors;
    @outlet CPTableView theTableView;
}
- (void)init
{
    self = [super init];
    [self setHeaderLabelHeight:20];
    [self setPhotoViewInset:10];
    // [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewContentBoundsDidChange:) name:CPViewBoundsDidChangeNotification object:self.scrollView.contentView];
    [self setCollectionViews:[[CPMutableArray alloc] init]];
    [self setCvArrayControllers:[[CPMutableArray alloc] init]];
        // These arrays should be given enough capacity as the symbolCollections are assembled, because it's important for their indexes
        // to correspond to the rows of the table.
    return self;
}

- (void)initializeSymbolCollections:(Classifier)aClassifier
{
    var i = 0,
        glyphs = [aClassifier glyphs],
        glyphs_count = [[aClassifier glyphs] count],
        symbolCollectionArray = [[CPMutableArray alloc] init];
    while (i < glyphs_count)
    // Assume the glyphs are sorted by id name.
    // Make an array for each id name.
    {
        var symbolCollection = [[SymbolCollection alloc] init],
            symbolName = [glyphs[i] idName],
            maxRows = 0,
            maxCols = 0;
        [symbolCollection setSymbolName:symbolName];
        for (; i < glyphs_count && [glyphs[i] idName] == symbolName; ++i)
        {
            if ([glyphs[i] nRows] > maxRows)
                maxRows = [glyphs[i] nRows];
            if ([glyphs[i] nCols] > maxCols)
                maxCols = [glyphs[i] nCols];
            [symbolCollection addGlyph:glyphs[i]];
        }
        [symbolCollection setMaxRows:maxRows];
        [symbolCollection setMaxCols:maxCols];
        [symbolCollectionArray addObject:symbolCollection];
    }
    // var symbolCollectionArrayController = [[CPArrayController alloc] init];
    [symbolCollectionArrayController setContent:symbolCollectionArray];
    var nSymbols = [[symbolCollectionArrayController contentArray] count];
    [collectionViews initWithCapacity:nSymbols];
    [cvArrayControllers initWithCapacity:nSymbols];
    for (var j = 0; j < nSymbols; ++j)
    {
        cvArrayControllers[j] = [[CPArrayController alloc] init];
        [cvArrayControllers[j] setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,-1)]];
    }
}
- (void)close
{
    [symbolCollectionArrayController setContent:[]];  // Also need to kill all of the subArrays.
      // Also need to unset all of the symbolCollections... the labels are bound to that model, and not through the array controller
      // Maybe the label ought to be bound through the array controller... like with objectValue (via the table's binding)
        // Use a dict of arrays keyed by symbol name.
    // var enumerator = [cvArrayControllerDict objectEnumerator],
    //     cvArrayController;
    // while (cvArrayController = [enumerator nextObject])
    // {
    //     [cvArrayController setContent:[]];
    // }
    // [cvArrayControllerDict removeAllObjects];
    [theTableView reloadData];
    // Ok.  I didn't even need the cvArrayControllerDict for this.  Wow.
    // So my first approach was sort of a 'binding' style approach in which I was hoping that the table view would
    // empty when I killed the content of the array controller.  However, I'm not using binding, I'm using a coded
    // approach, because of all of the hooplah with the collection view and the row height.  So the best binding
    // could do would be to empty the coll views and labels, but the tableView would still sort of be there (and the
    // scroll bar,) so it's much better to just tell the tableView what to do explicitly (reloadData... after erasing
    // the data).  Side note: the SymbolOutline uses the former approach (binding.)
}





// ------------------------------------- DELEGATE METHODS ----------------------------------------------





- (CPView)tableView:(CPTableView)aTableView viewForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
// Return a view for the TableView to use a cell of the table.
{
    var aView = [[ViewWithObjectValue alloc] initWithFrame:CGRectMakeZero()];
    return aView;
}
- (void)tableView:(CPTableView)aTableView willDisplayView:(CPView)aView forTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
// Set up the view to display.  (Delegate method.)
// (Note: I do things in this function so that I have access to objectValue... which I don't in viewForTableColumn.)
{
    console.log("---willDisplayView---");
    var symbolCollection = [[aTableView dataSource] tableView:aTableView objectValueForTableColumn:aTableColumn row:aRow],
        symbolName = [symbolCollection symbolName],  // If I use binding, I don't need this variable
        label = [[CPTextField alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth([aView bounds]), [self headerLabelHeight])];
    [label setStringValue:symbolName];
    [label setFont:[CPFont boldSystemFontOfSize:16]];
    [label setAutoresizesSubviews:NO];
    [label setAutoresizingMask:CPViewWidthSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin];
    [aView addSubview:label];

    var parentView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    [aView setAutoresizesSubviews:NO];
        //It's driving me bonkers: why doesn't the label get pinned to the top of aView upon resize???  (Not using Autosize!)
    [aView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [parentView setAutoresizesSubviews:NO];
    [parentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [aView addSubview:parentView];
    [parentView setFrame:CGRectMake(0, [self headerLabelHeight], CGRectGetWidth([aView bounds]), CGRectGetHeight([aView bounds]) - [self headerLabelHeight])];
    // var cvArrayController = [[CPArrayController alloc] init];
    // [cvArrayControllerDict setObject:cvArrayController forKey:symbolName];
    // [cvArrayControllers insertObject:cvArrayController atIndex:aRow];
    // var cv = [self _makeCollectionViewForTableView:aTableView arrayController:cvArrayController parentView:parentView row:aRow];
    var cv = [self _makeCollectionViewForTableView:aTableView arrayController:cvArrayControllers[aRow] parentView:parentView row:aRow];
    [cv bind:@"selectionIndexes" toObject:cvArrayControllers[aRow] withKeyPath:@"selectionIndexes" options:nil];
    // [cvArrayControllers[aRow] setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,-1)]];  // Hopefully won't have one selected at the beginning
    //  commented: do not want to do this each time the view is displayed (scrolled past)
    [collectionViews insertObject:cv atIndex:aRow];  // Do I need this?
        // Again... there should be an 'if' at the beginning of this that checks if I need a new view!  I probably only need to do this the 1st time the view's displayed...
        // First make sure that the array controller's working, then explore that.
    // Hmmm... selection is starting to work.
    // But I think that I shouldn't make a new collection view every time willDisplayView is called.
    // Instead, the collection view should (and can) be set up in viewForTableColumn (every since I set up the data source, I haven't moved it.)
    // On second thought, maybe the collectionView DOES get remade each time.  But the array controller should be pervasive.
    // -> Set up all the array controllers in initialize.

}

- (void)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
// (Data source method)
{
    return [symbolCollectionArrayController arrangedObjects][aRow]; // (Ignoring the column... the table has only one column)
}
- (void)numberOfRowsInTableView:(CPTableView)aTableView
// (Data source method)
{
    return [[symbolCollectionArrayController contentArray] count];
}
- (void)tableView:(CPTableView)aTableView heightOfRow:(int)aRow
// Returns the height of a specified row.  (Delegate method.)
{
    var ac = [[CPArrayController alloc] init],
        dummyView = [[CPView alloc] initWithFrame:CGRectMake(1,1,CGRectGetWidth([aTableView bounds]),1)],
        _cv = [self _makeCollectionViewForTableView:aTableView arrayController:ac parentView:dummyView row:aRow],
        symbolCollection = [[aTableView dataSource] tableView:aTableView objectValueForTableColumn:nil row:aRow],
        glyphWidth = [symbolCollection maxCols] + (2 * [self photoViewInset]),
        glyphCount = [[symbolCollection glyphList] count],
        tableWidth = CGRectGetWidth([aTableView bounds]),
        number_of_rows_in_collection_view = Math.ceil((glyphWidth * glyphCount) / tableWidth),
        bottom_image_frame = [[_cv subviews][[[_cv subviews] count] - 1] frame],
        bottom_of_last_image = CGRectGetMaxY(bottom_image_frame),
        cell_spacing_neglected_by_collection_view = bottom_of_last_image - CGRectGetHeight([_cv bounds]);
    return CGRectGetHeight([_cv bounds]) + cell_spacing_neglected_by_collection_view * number_of_rows_in_collection_view + [self headerLabelHeight];
    // Let me explain the ridiculousness here.
    // First, read http://stackoverflow.com/questions/7504546 and understand that we need to build a dummy collection
    // view to solve the chicken&egg problem: we need to build a dummy coll view so that we can assign a row height,
    // which we need to do before building the coll view that goes in the table, because that view needs the row height
    // to render itself.
    // Now, that approach ALMOST worked, but it seems that when the coll. view underestimates its size (fogetting about the
    // space between cells, and if there is more than one row, then there is cutoff.  If there are a lot of rows, there is a
    // lot of cutoff.)
    // This problem is partly solved by reading the max y coordinate of the last image in the collection view, and using that
    // in the row height.  Unfortunately, you need to repeat that algorithm for each row in the collection view, because the
    // view rearranges itself and continues to spill out to be larger than the row.  You need to calculate the number of rows
    // in the collection view, and iterate the correction that number of times.
    // Now, it turns out each such iteration adds the SAME amount, so instead of iterating, I'll do it once, and then add
    // according to how much height was added.  Again, that amount is the difference between the cv's reported height and
    // the height found by looking at the bottom of the last image.
    // I can't think of another algorithm that solves this problem, so that's what I implemented

    // There seems to be a minor width issue.  See if the coll view's width is actually wider than it should be... Consider building it in a smaller view (?)
    //   (?) because that never worked for me before, I think it must be laid out inside the tableView's aView... which I don't think gives me leeway...
    //   unless I call setFrame on the collView.  Worth a shot.
}
- (void)recheck_heights:(CPView)aCvParentView
{
    var _cv = [aCvParentView subviews][0];
    console.log("---In recheck_heights!---");
    console.log("parent view height: " + CGRectGetHeight([aCvParentView frame]));
    console.log("cv height: " + CGRectGetHeight([_cv frame]));
    console.log("calculate from last image: " + CGRectGetMaxY([[_cv subviews][[[_cv subviews] count] - 1] frame]));
    console.log("---Out recheck_heights!---");
    return;
}
- (CPCollectionView)_makeCollectionViewForTableView:(CPTableView)aTableView arrayController:(CPArrayController)cvArrayController parentView:(CPView)aView  row:(int)aRow
{
    var model = [[aTableView dataSource] tableView:aTableView objectValueForTableColumn:nil row:aRow],
        cv = [[CPCollectionView alloc] initWithFrame:CGRectMakeZero()];
    [cv setAutoresizesSubviews:NO];
    [cv setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinXMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [cv setMinItemSize:CGSizeMake(0,0)];  // Aha!  Now that the PhotoView has a frame, this works.  (the size isn't determined by this.)
    [cv setMaxItemSize:CGSizeMake(10000, 10000)];
    [cv setDelegate:self];
    [cv setSelectable:YES];
    [cv setAllowsMultipleSelection:YES];
    var itemPrototype = [[CPCollectionViewItem alloc] init],
        photoView = [[PhotoView alloc] initWithFrame:CGRectMakeZero() andInset:[self photoViewInset]];
    [photoView setBounds:CGRectMake(0,0,[model maxCols],[model maxRows])];
    [photoView setFrame:CGRectMake(0,0,[model maxCols] + (2 * [photoView inset]), [model maxRows] + (2 * [photoView inset]))];
    [photoView setAutoresizesSubviews:NO];
    [photoView setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [itemPrototype setView:photoView];
    [cv setItemPrototype:itemPrototype];
    [cv bind:@"content"
        toObject:cvArrayController
        withKeyPath:@"arrangedObjects"
        options:nil];
    [aView addSubview:cv];
    [cvArrayController setContent:[model glyphList]];
    // console.log("_make returning cv for row: " + aRow + " of height: " + CGRectGetHeight([cv frame]));
    return cv;
}
- (void)tableViewColumnDidResize:(CPNotification)aNotification
{
    console.log("Resized.");
    var tableView = [aNotification object];
    [tableView noteHeightOfRowsWithIndexesChanged:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,[tableView numberOfRows])]];
        // Maybe turn off animation for the above command
    // [tableView reloadData];  // Seems to perform about the same as reloadDataForRowIndexes
    var scrollView = [[tableView superview] superview],
        visibleRows = [tableView rowsInRect:[[scrollView contentView] bounds]];
    [tableView reloadDataForRowIndexes:visibleRows columnIndexes:0];
        // see http://stackoverflow.com/questions/12067018 for other approaches
}
// This function will help with selection... find a way to pass the event to the collection view
- (void)tableView:(CPTableView)aTableView shouldSelectRow:(int)aRow
// Returns the height of a specified row
{
    // var glyphs = [[[aTableView dataSource] tableView:aTableView objectValueForTableColumn:nil row:aRow] glyphList];
    console.log("Selecting glyphs for row " + aRow + ".");
    // console.log(glyphs);
    // if(! [cvArrayControllers[aRow] setSelectedObjects:glyphs] )
    if(! [cvArrayControllers[aRow] setSelectedObjects:[cvArrayControllers[aRow] contentArray]] )
    {
        console.log("if true");
        console.log("Selection did not change (all must have been selected.)");
        [cvArrayControllers[aRow] setSelectedObjects:[]];
        // [collectionViews[aRow] setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,0)]];
    }
    else
    {
        console.log("else");  // Always else.
        // Telling the collection view to show its selection (aha!  the better way would be to bind its selection to the array controller, which happens in Rodan)
        // [collectionViews[aRow] setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,[[cvArrayControllers[aRow] contentArray] count])]];
    }
    // console.log("Changed selection.  cvArrayController[" + aRow + "]:");
    // console.log(cvArrayControllers[aRow]);
    // console.log(cvArrayControllers);
}
@end
