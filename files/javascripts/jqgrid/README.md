This version of `jquery.jqGrid.min.js` was generated from the forked jqGrid source at <https://github.com/davec/jqGrid>,
using the [Google Closure Compiler](http://code.google.com/closure/compiler/docs/overview.html) for minification.

The modified code includes fixes from the [uniform-row-height-for-virtual-scrolling](https://github.com/davec/jqGrid/tree/uniform-row-height-for-virtual-scrolling)
and [keep-loading-indicator-until-done](https://github.com/davec/jqGrid/tree/keep-loading-indicator-until-done) branches.
These fixes address two problems with virtual scrolling: (1) non-uniform row heights
that either prevented the full table from being loaded, or caused duplicate pages
to be loaded when scrolling to the end of the table; and (2) quickly scrolling of
the table that resulted in pages being loaded out of order and the pager showing
strange values (e.g., "View -79 - 120 of 150").
