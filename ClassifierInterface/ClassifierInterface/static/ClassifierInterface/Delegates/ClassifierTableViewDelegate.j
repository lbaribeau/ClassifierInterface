@import "../Views/PhotoView.j"
@import "../Views/ViewWithObjectValue.j"
@import "../Models/SymbolCollection.j"
@import "../Models/Classifier.j"

@implementation ClassifierTableViewDelegate : CPObject
{
    @outlet CPArrayController symbolCollectionArrayController;  // Debug
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
    [self setCvArrayControllers:[[CPArray alloc] init]];
    return self;
}

// - (void)initializeSymbolCollections:(Classifier)aClassifier
- (void)initializeSymbolCollections:(CPArrayController)classifierGlyphsArrayController
{
    var i = 0,
        // glyphs = [aClassifier glyphs],
        glyphs = [classifierGlyphsArrayController arrangedObjects],
        glyphs_count = [glyphs count],
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
    [symbolCollectionArrayController setContent:symbolCollectionArray];
    var nSymbols = [[symbolCollectionArrayController contentArray] count];
    [cvArrayControllers initWithCapacity:nSymbols];
    for (var j = 0; j < nSymbols; ++j)
    {
        cvArrayControllers[j] = [[CPArrayController alloc] init];
        // [cvArrayControllers[j] setContent:[symbolCollectionArray[j] glyphList]];
        // [cvArrayControllers[j] bind:@"content" toObject:symbolCollectionArray[j] withKeyPath:@"glyphList" options:nil];  // try contentArray!
        [cvArrayControllers[j] bind:@"contentArray" toObject:symbolCollectionArray[j] withKeyPath:@"glyphList" options:nil];  // try contentArray!
        // [cvArrayControllers[j] setAvoidsEmptySelection:NO];  // May affect selection after deletion, default is YES
        [cvArrayControllers[j] setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,0)]];
    }
}
- (void)writeSymbolName:(CPString)newName
{
        // I need to map the arrayControllers to theClassifier to get write to work.
        // I don't need a global array controller if I just do some math :)  I love math.
        // Unfortunately it's not efficient though.  I'd have to get the count from every array with less of an index.
        // Maybe I'll do this global selection array controller.  I don't think I can do it with bindings.  Maybe I can
        // do it by writing code into observeValueForKeyPath... code that will (manually) update the global array controller
        // data.  It's not done via binding, but I think it's still complete.
        // ( Unfortunately I have two models to update now... theClassifier for the server and symbolCollections for the client.
        // MAYBE SymbolCollections look at the same data (in theClassifier)  That'd be sweet. )
        // OK:  Try using the array controllers that we already have.  ClassifierTableViewDelegate.cvArrayControllers

    // At the beginning, make a new bin based on the new name (if it's needed) and then calculate the correction of +1
    // for the array controllers.  (Make a new array controller for the new bin also.)
    // I could just call initialize again :P  Hahaha.  We are in hack mode
    // TODO: Write this function that properly maintains symbolCollections for when a symbol changes name.  (For now, I just reload
    // the things and let init to the work.)

    var symbolCollectionArray = [symbolCollectionArrayController arrangedObjects],
        symbolCollectionArray_count = [symbolCollectionArray count],
        bin_already_exists = false,
        newBinIndex = 0;

    // TODO: Optimize, maybe with filters
    // Assume sorted
    for (; newBinIndex < symbolCollectionArray_count; ++newBinIndex)
    {
        if ([symbolCollectionArray[newBinIndex] symbolName] === newName)
        {
            bin_already_exists = true;
            break;
        }
        else if ([symbolCollectionArray[newBinIndex] symbolName] > newName)
        {
            console.log("Exiting at newBinIndex " + newBinIndex + " as a bucket doesn't exist for that name.");
            break;
        }

    }
    console.log("bin_already_exists: " + bin_already_exists);
    if (! bin_already_exists)
    {
        // Make a bin (a symbolCollection).
        var newSymbolCollection = [[SymbolCollection alloc] init];
        [newSymbolCollection setSymbolName:newName];
        console.log("Adding new symbolCollection with name " + [newSymbolCollection symbolName] + ".");
        // [symbolCollectionArrayController addObject:newSymbolCollection];  // Don't worry about sorting, let arrangedObjects do that.
        [symbolCollectionArrayController insertObject:newSymbolCollection atArrangedObjectIndex:newBinIndex];
        // Set maxRows and maxCols later.

        ++symbolCollectionArray_count;  // Gets used in later loops(?)

        // need to alloc a new array controller.
        [cvArrayControllers insertObject:[[CPArrayController alloc] init] atIndex:newBinIndex];
        // [cvArrayControllers[newBinIndex] setContent:[newSymbolCollection glyphList]];
        // [cvArrayControllers[newBinIndex] bind:@"content" toObject:newSymbolCollection withKeyPath:@"glyphList" options:nil];
        [cvArrayControllers[newBinIndex] bind:@"contentArray" toObject:newSymbolCollection withKeyPath:@"glyphList" options:nil];
        // [cvArrayControllers[j] setAvoidsEmptySelection:NO];  // May affect selection after deletion, default is YES
        [cvArrayControllers[newBinIndex] setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,0)]];
        // Maybe that should have been a function because it's common code with init.
    }
    // newSymbolCollection is now set.
    var cvArrayControllers_count = [cvArrayControllers count],
        removalIndexAdjustment = 0;
    for (var i = 0; i < cvArrayControllers_count; ++i)
    {
        // var selectedObjects = [cvArrayControllers[i] selectedObjects],
        //     selectedObjects_count = [selectedObjects count];
        // // console.log([selectedObjects copy]);
        // // console.log(selectedObjects);
        // // console.log([symbolCollectionArrayController contentArray]);

        // for (var j = 0; j < selectedObjects_count; ++j)
        // {
        //     console.log("Inside j loop (found " + selectedObjects_count + " selectedObject.");
        //     // Remove selectedObjects from their current symbolCollection bin
        //     // for (var k = 0; k < symbolCollectionArray_count; ++k)
        //     // {
        //     //     if ([symbolCollectionArray[k] symbolName] === [selectedObjects[j] idName])
        //     //     {
        //     //         // [self _removeGlyph:selectedObjects[j] fromSymbolCollection:symbolCollectionArray[j]];
        //     //         // symbolCollectionArray[j] addGlyphAndUpdateMaxRowAndMaxCol
        //     //         // I should actually just write [symbolCollection addGlyph] to keep maxRows and maxCols up to date.
        //     //         // Well, it would be nicer to read but a little slower, so yeah it'd be better, but I'd also have to rewrite
        //     //         // init.  I think I will do it, and not rewrite init, because init will work either way.
        //     //         console.log("Removed glyph with name " + [selectedObjects[j] idName] + " from symbolCollection " + k);
        //     //         console.log([[symbolCollectionArray[j] glyphList] count]);
        //     //         [symbolCollectionArray[k] removeGlyph:selectedObjects[j]];  // make sure that the cvArrayController figures this out

        //     //         console.log([[symbolCollectionArray[j] glyphList] count]);
        //     //         if ([[symbolCollectionArray[k] glyphList] count] === 0)
        //     //         {
        //     //             // Remove this symbolCollection, and update symbolCollectionArray_count
        //     //             [symbolCollectionArray removeObjectAtIndex:[k]];
        //     //             --symbolCollectionArray_count;
        //     //             console.log("Just removed a symbolCollection:");
        //     //             console.log(symbolCollectionArray);
        //     //             // Now the collectionView is complaining... I wonder whether it's one that needs to display, because I don't really need it to.
        //     //         }
        //     //         break;
        //     //     }
        //     // }
        //     // [symbolCollectionArray[i] removeGlyph:selectedObjects[j]];
        //     [cvArrayControllers removeObject:selectedObjects[j]];  // This may break the loop unless we decrement j
        //     // --j;  // do this at the end
        //     // need to decrement newBinIndex too if j is less than it.
        //     [symbolCollectionArray[i] removeGlyph:selectedObjects[j]];
        //     // There will be a problem when length is now zero, but I'm still working on a different problem.

        //     console.log("Changing name of glyph from " + [selectedObjects[j] idName] + " to " + newName);
        //     [selectedObjects[j] writeSymbolName:newName];
        //     // Add to the new bin
        //     // Need to get rid of this loop... set newBin at the beginning
        //     // for (var k = 0; k < symbolCollectionArray_count; ++k)
        //     // {
        //     //     if ([symbolCollectionArray[k] symbolName] === [selectedObjects[j] idName])
        //     //     {
        //     //         // [self _addGlyph:selectedObjects[j] toSymbolCollection:symbolCollectionArray[j]];
        //     //         console.log("Adding glyph with name " + [selectedObjects[j] idName] + " to symbolCollection " + k);
        //     //         [symbolCollectionArray[k] addGlyph:selectedObjects[j]];
        //     //         break;
        //     //     }
        //     // }
        //     // [symbolCollectionArray[k] addGlyph:selectedObjects[j]];
        //     // [newSymbolCollection addGlyph:selectedObjects[j]];
        //     if (bin_already_exists)
        //     {
        //         [cvArrayControllers[newBinIndex] addObject:selectedObjects[j]];  // Ugh... will work if we didn't need to add a bin, but if not, we don't have an array controller.
        //         // Actually, that's ok!  Just don't do it if there isn't one, reloadData will make one.
        //     }

        //     // It would be better to save the new bin index so that I can update both the cvArrayController and the symbolCollection


        //     // Don't need this line as I already have a loop going above
        //     // [selectedObjects makeObjectsPerformSelector:@selector(writeSymbolName:) withObject:newName];
        //     // console.log("Made objects write " + newName + ".");
        //     // console.log(selectedObjects);
        //     // console.log([symbolCollectionArrayController contentArray]);  // not right yet... init is later.

        //     // Maintain the structure of symbolCollections
        //     //  If there's no bin for the new name, insert one.
        //     //  Move the glyph into the new bin.
        //     // Also be sure that maxRows and maxCols are updated
        //     // var symbolCollection = [symbolCollectionArrayController contentArray][i];  // Won't work if we do inserts in this loop
        //     // for (var j = 0; j < [selectedObjects count]; ++j)
        //     // {
        //     //     if ([[symbolCollection glyphList] containsObject:selectedObjects[j]])
        //     //     {
        //     //         // Move the glyph to the new bin and update symbolCollections
        //     //     }
        //     // }
        // }
        var selectedObjects = [cvArrayControllers[i] selectedObjects];

        // Try it as a one-shot
        // [cvArrayControllers[i] remove:self];  // Removes the controller's selected objects from the controller's collection

        while([selectedObjects count] > 0)
        {
            var glyph = selectedObjects[0];
            [cvArrayControllers[i] removeObject:glyph];  // Maybe I don't need this?  We'll see.
            // [cvArrayControllers[i] removeSelectedObjects:glyph];  // This may cause nullify to be called incorrectly, but should work for one selection
            // We can assume that arranged objects aligns with cvArrayControllers... but not so much with the simple array, especially after the insert before
            // Experiment with preservesSelection
            // [[symbolCollectionArrayController arrangedObjects][i] removeGlyph:glyph];  // Better confirm this first if there's an issue
            if ([[[symbolCollectionArrayController arrangedObjects][i] glyphList] count] === 0)
            {
                [symbolCollectionArrayController removeObjectAtArrangedObjectIndex:i];  // will shift left everything, so [i] is now the next item
                [cvArrayControllers removeObjectAtIndex:i];  // The collection view might complain... hopefully not too much
                --symbolCollectionArray_count;  // Doesn't get used
                --cvArrayControllers_count;  // Used by for loop
                ++removalIndexAdjustment;  // unneeded
                // --i;  // Hmmm, is this necessary?  I don't think so, I think I can continue with the same i (which is the next i)
                    // I guess I did it to counteract the for loop's ++. I think the code will work either way in most cases, so I'm going to remove it.
                    // (With the -- in, then the while loop will just iterate again in the way that the for loop normally would.)
                    // Maybe I don't need the while... and it can be one loop.  Nah, the while is for selectedObjects, the for is for table rows
                if (newBinIndex > i)
                {
                    --newBinIndex;
                }
                // By the way, the while loop will end on this iteration,
                // since selectedObjects will certainly be zero if that was the last glyph in the collection
                // Code for --i:
                // [glyph writeSymbolName:newName];
                // [cvArrayControllers[newBinIndex] addObject:glyph];
                // [[symbolCollectionArrayController arrangedObjects][newBinIndex] addGlyph:glyph];
                // break;  // the for loop will increment i back to the same value, and we'll continue from there
                //         // Maybe instead I won't bother with going through the next for, I'll just leave i alone and do the while again.
            }
            [glyph writeSymbolName:newName];
            console.log("Should update cvArrayController contentArray");
            // debugger;
            console.log([[cvArrayControllers[newBinIndex] contentArray] count]);
            console.log([[cvArrayControllers[newBinIndex] arrangedObjects] count]);
            // Maybe the symbolCollection should HAVE the array controller.
            // Maybe theClassifier should in fact be an array of symbolCollections
            [[symbolCollectionArrayController arrangedObjects][newBinIndex] addGlyph:glyph];
            // [cvArrayControllers[i] addObject:glyph];  // Should affect the symbolCollection  ... unless I need to bind the symbolCollection to the array controller
                // it doesn't affect the symbolCollection
                // It also doesn't update maxes, but I suppose I could call that.
            console.log([[cvArrayControllers[newBinIndex] contentArray] count]);
            console.log([[cvArrayControllers[newBinIndex] arrangedObjects] count]);  // Try instead of addGlyph, go through the cvArrayController.  (Never use addGlyph)
                // Gwargh, arrangedObjects doesn't increase.  Better stop using it.
            // [cvArrayControllers[newBinIndex] addObject:glyph];  // Shouldn't need to do this as it's bound to the symbolCollection... should be sufficient to just use the symbolCollectionArrayController
            [cvArrayControllers[newBinIndex] setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,0)]];  // Maybe don't need this, try setSelectedInsertedObjects

            // selectedObjects = [cvArrayControllers[i] selectedObjects];  // Good, same i.  If we removed an object, then this is equivalent to iterating the for loop (but we just stick with the while loop)
            // Also keep in mind that for now, we're probably not going to handle error where it was the last glyph...
            // But it might be good to at least
            selectedObjects = [selectedObjects removeObjectAtIndex:0];
        }
        // I think the problem is due to the new collection view.
        // Maybe shouldSelectRow can give a hint

        // while([selectedObjects count] > 0)
        // {
        //     var glyph = selectedObjects[0];
        //     [cvArrayControllers[i+removalIndexAdjustment] removeObject:glyph];
        //     // [symbolCollectionArray[i] removeGlyph:glyph];
        //     // We can assume that arranged objects aligns with cvArrayControllers... but not so much with the simple array, especially after the insert before
        //     [[symbolCollectionArrayController arrangedObjects][i+removalIndexAdjustment] removeGlyph:glyph];  // Better confirm this first if there's an issue
        //     if ([[[symbolCollectionArrayController arrangedObjects][i+removalIndexAdjustment] glyphList] count] === 0)
        //     {
        //         [symbolCollectionArrayController removeObjectAtArrangedObjectIndex:i+removalIndexAdjustment];
        //         [cvArrayControllers removeObjectAtIndex:i+removalIndexAdjustment];  // The collection view might complain... hopefully not too much
        //         --symbolCollectionArray_count;  // Doesn't get used
        //         --cvArrayControllers_count;
        //         ++removalIndexAdjustment;
        //         --i;
        //         if (newBinIndex > (i + removalIndexAdjustment)
        //         {
        //             --newBinIndex;
        //         }
        //         // By the way, the while loop will end on this iteration,
        //         // since selectedObjects will certainly be zero if that was the last glyph in the collection
        //     }
        //     [glyph writeSymbolName:newName];
        //     [cvArrayControllers[newBinIndex] addObject:glyph];
        //     [[symbolCollectionArrayController arrangedObjects][newBinIndex] addGlyph:glyph];
        //     selectedObjects = [cvArrayControllers[i] selectedObjects];
        //     // Also keep in mind that for now, we're probably not going to handle error where it was the last glyph...
        //     // But it might be good to at least
        // }
    }
    console.log(symbolCollectionArray);  //
    console.log("Got here!");
    [theTableView noteNumberOfRowsChanged];
    [theTableView reloadData];  // breaks if an item was removed from the symbolCollectionArray (from which the tableView gets its data... but it's not a binding)
                                // but the collectionViews are bound.  Maybe I can unbind them or something, or maybe they ought to be smarter.
    // I need new collection views.
    console.log("And here!");


    // At the end, make sure that the new bin has something in it.  (Shouldn't be necessary.)

    // for (var i = 0; i < [selectedObjects count]; ++i)
    // {
    //     [selectedObjects[i] writeSymbolName:newName];
    // }

    // [classifierTableView reloadData];  // Uncomment this when properly rewriting this function.
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
    // console.log('---viewForTableColumn---');
    // if (cachedViews[aRow])
    // {
    //     return cachedViews[aRow];
    // }
    // else
    // {
    //     cachedViews[aRow] = [[ViewWithObjectValue alloc] initWithFrame:CGRectMakeZero()];
    //     return cachedViews[aRow];  // Nope... doesn't display!
    // }
    // console.log([cvArrayControllers[0] selectionIndexes]);
    return [[ViewWithObjectValue alloc] initWithFrame:CGRectMakeZero()];
}
- (void)tableView:(CPTableView)aTableView willDisplayView:(CPView)aView forTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
// Set up the view to display.  (Delegate method.)
// (Note: I do things in this function so that I have access to objectValue... which I don't in viewForTableColumn.)
{
    console.log("---willDisplayView--- row " + aRow);
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
    var cv = [self _makeCollectionViewForTableView:aTableView arrayController:cvArrayControllers[aRow] parentView:parentView row:aRow];
    // [cv bind:@"selectionIndexes" toObject:cvArrayControllers[aRow] withKeyPath:@"selectionIndexes" options:nil];
    [cv setSelectionIndexes:[cvArrayControllers[aRow] selectionIndexes]];  // This should allow you to scroll down and back and have the selection persist
        // Now... when did cvArrayControllers[aRow] selectionIndexes get erased!
        // Maybe the binding isn't working... or maybe the array controller
    [cvArrayControllers[aRow] bind:@"selectionIndexes" toObject:cv withKeyPath:@"selectionIndexes" options:nil];
        // Note: this is a clever binding.  We don't want to bind the view to the array controller because the view is transitory
        // and we'd end up with an accumulation of bindings.
        // Gweh.  Problem: rename a couple of symbols, and then you can't select a symbol that has been renamed.  Maybe the array controller
        // is still bound to the old collection view.  It'd be nice to get multi-select working on a glyph that has been moved... I think that
        // would solve the issue.  Is it an issue with this binding?  Yeah... I need to make sure that I get a new cView if a move has happened.
        // Maybe reloadData isn't enough.  The array controller needs to bind to the cv with the new item in it.
        // Well is that even true... I think so... it would explain the behavior anyway (not all things being selected.)
        // Well NO, the reason not all things are selected is because of shouldSelectRow and that the ac CONTENT MUST get the new item!
        // Rodan:     [runsArrayController bind:@"contentArray" toObject:workflowObject withKeyPath:@"workflowRuns" options:nil];
        //
    console.log("Binding cvArrayController " + aRow + " selectionIndexes to new cv with " + [[cv content] count] + " items");
        // This is just selection indexes... what about content?  Content goes the other way: the cv binds to the ac arranged objects.
    [cv addObserver:self forKeyPath:@"selectionIndexes" options:nil context:aRow];  // allows observeValueForKeyPath function
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(CPCollectionView)aCollectionView change:(CPDictionary)aChange context:(id)aContext
// KVO (Key Value Observing) method.  This is how I trigger code when the collection view changes selection.
// References:
// 1. NSKeyValueObserving Protocol Reference
// 2. http://www.cocoabuilder.com/archive/cocoa/220039-nscollectionview-getting-notified-of-selection-change.html
// addObserver and implement the right method on the observer (use a new class: collectionViewObserver)
// aChange is a neato dictionary.
// aContext is the row that got clicked.
{
    // console.log("observeValueForKeyPath");

    var theClickedRow = aContext;
    // Check if the new indexSet is empty.
    var newIndexSet = [aChange valueForKey:@"CPKeyValueChangeNewKey"];
    if (([newIndexSet firstIndex] !== CPNotFound) && ! ([[CPApp currentEvent] modifierFlags] & (CPShiftKeyMask | CPCommandKeyMask)))  //http://stackoverflow.com/questions/9268045
    {
        // console.log("Nullifying the selection on all other rows.");
        var i = 0,
            nArrayControllers = [cvArrayControllers count];
        for (; i < nArrayControllers; ++i)
        {
            if (i !== theClickedRow)
            {
                [cvArrayControllers[i] setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,0)]];
                // The reason that we ensure that firstIndex != CPNotFound is because this line of code causes ANOTHER call to observeValueForKeyPath.
                // So we break an infinite loop by only nullifying other views' selections if the newIndexSet has a firstIndex (which isn't true for
                // this line's change of selection)
                // This might cause a problem when I change the indices from the SymbolTable.  Maybe I will unbind and rebind the cv as I do that.
                // However, I'm leaving that function till later.
            }
        }
        // This part actually gets called TWICE when once would be enough.
        // For some reason observeValueForKeyPath gets called twice when you click a new collection view.  The first aChange doesn't make sense:
        // both 'old' and 'new' contain the same indexSet.  I don't feel the need to figure what why the first change happens.
    }
    // Ok, so what do?
    // if not shift*
    //   nullify selections of all other array controllers
    //   if no change and it's a single selection
    //     default (I don't feel the need to allow deselection... they can ctrl click if they really want)
    //   else
    //     default (don't implement) (let the change go through)
    // if shift
    //   default

    // It would be REALLY nice if I had that global array that was a composition of all the collection view arrays.
    // That way, on a shift click, I could ask that array controller for an index, and then make a range from there
    // to the new click.

    // Another task for this function: maintain the selection indexes of a global array controller.  OR just loop through the ones I have
    // each time someone hits enter on the text box.  If the models are looking at the same data, that SHOULD work.
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
    // console.log("_make for row " + aRow);
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
    // var glyphListArrayController = [[[CPArrayController alloc] init] setContent:[model glyphList]];
    // [photoView bind:@"toolTip" toObject:glyphListArrayController withKeyPath:@"arrangedObjects" options:nil];  // doesn't work.
    [itemPrototype setView:photoView];
    [cv setItemPrototype:itemPrototype];
    // [cv bind:@"content" toObject:cvArrayController withKeyPath:@"arrangedObjects" options:nil];
    [cv bind:@"content" toObject:cvArrayController withKeyPath:@"contentArray" options:nil];
        // I'm having an issue where selecting a moved glyph doesn't work.
        // I thought it was because the collection view was binding to arrangedObjects, which wasn't getting added to while
        // contentArray was.  For now, I'm going to rule that out by binding to contentArray.  contentArray is the glyphList.

    [aView addSubview:cv];
    // [cvArrayController setContent:[model glyphList]];
        // I think this erases my selection indexes... but I do it to kick the collection view to display...
        // I think that I'll start a pattern of BINDING LATER (after content is set,) and just kicking the view with setContent
        // The binding handles CHANGES, but doesn't need to handle the initialization, because it constrains the order of operation too much.
        // Careful about changing this though... it'll affect the row height calculation.
        // That will be fixed by using the same array controller from the row height (in fact, just delete that argument.)
    [cv setContent:[model glyphList]];  // Hopefully the binding still works, I'll have to test that later.
        // Recall: I had to interrupt the pattern of ONLY BINDING and NOT CALLING SetContent because that required that
        // I setContent of the array controller AFTER the view has been bound.  However, the view has to be rebuilt whenever you
        // scroll past it, so I cannot setContent of the array controller that often!  It erases the selection!  That, in short,
        // is why I need to both BIND and setContent.

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
    console.log("ShouldSelectRow: [[cvArrayControllers[aRow] selectionIndexes] count] is " + [[cvArrayControllers[aRow] selectionIndexes] count] +
        ", [[cvArrayControllers[aRow] contentArray] count] is " + [[cvArrayControllers[aRow] contentArray] count]);
    [cvArrayControllers[aRow] rearrangeObjects];
    if ([[cvArrayControllers[aRow] selectionIndexes] count] === [[cvArrayControllers[aRow] contentArray] count])
    {
        // all are selected
        console.log("ShouldSelectRow: deselecting items.");
        [cvArrayControllers[aRow] setSelectedObjects:[]];
    }
    else
    {
        console.log("ShouldSelectRow: selecting " + [[cvArrayControllers[aRow] contentArray] count] + " items.");
        [cvArrayControllers[aRow] setSelectedObjects:[cvArrayControllers[aRow] contentArray]];
        // Not setting all four... hmmm.  Print selectedObjects and contentArray... try to determine why the fourth isn't set.
        console.log([cvArrayControllers[aRow] selectedObjects]);
        console.log([cvArrayControllers[aRow] contentArray]);  // Maybe KVC doesn't get notified by addGlyph?  But content array's count goes up I think.
    }
    return NO;
}
// Hmmm deselect of a single element?  Not needed as much as the collection views talking to eachother.
// Persistent selection is just fine (only deselect when a new thing is selected...)
// but I want a more global selection object.  When a second collection view is clicked, then I need to deselect from the first
// collection view, AND when a second is clicked with shift clicked, I need to retain the selection.
// I need a really global array controller... that is just all of the cvArrayControllers in series... so the collectionViews
// are bound to the little array controllers... I don't think I can bind them to a subArray of the global one... so all that code
// will stay... so I need to write a wrapper/handler that responds to every change in selection of any array controller...
// maybe I can bind...
// The handler should subscribe to ALL changes in selection (the controller must have a selectionDidChange,)... then it can also
// have full control of what happens: it can deselect all selections in the other controllers if shift isn't pressed, etc.  Then
// the text box can take its cues from the global controller.  Call it SelectionController.  It can have the TableViewDelegate and
// the SymbolTableDelegate.  It won't need the table view, because the collectionViews are bound to the array controllers, (so they
// won't need to be kicked.)  It only needs the symbolTable's array controller because it can calculate everything it needs from the
// selection<Symbol>.name.
// Well... I'm not sure that the array controller has such a notification, but the collection views do!  I'll just set them all
// to have the same delegate!
@end
