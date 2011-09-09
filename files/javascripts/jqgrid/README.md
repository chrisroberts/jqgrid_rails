This version of `jquery.jqGrid.min.js` was generated from the forked jqGrid source at <https://github.com/davec/jqGrid>,
using the [Google Closure Compiler](http://code.google.com/closure/compiler/docs/overview.html) for minification.

The modified code includes fixes from the [override-request-type-for-inline-edit](https://github.com/davec/jqGrid/tree/override-request-type-for-inline-edit)
and [explicit-jquery-onclick-values](https://github.com/davec/jqGrid/tree/explicit-jquery-onclick-values) branches.
These fixes (1) allow inline edits to change the request type from the default
POST to a PUT, to be compatible with Rails' resource routes and (2) change the
usage of `$` to `jQuery` to avoid conflict with `$` in Prototype.

Pull requests were sent to @tonytomov on 2011-09-02.
