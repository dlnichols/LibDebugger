# LibDebugger
LibDebugger is an AddOn for The Elder Scrolls Online, aimed to create a fully
functional REPL/debugger for AddOn development.

## To Do
* Configuration Stuff
* Fixed Width Font in the History Box
* Watch List
* Pretty Printing
* Scrolling History
* Tab Completion

## Major Features
* GUI Debug Console / REPL

## Commands (type these in the normal chat window)
    /debug - Use this command to being up the debug console
      Arguments:
      show   - Show the debugger
      hide   - Hide the debugger
      toggle - Toggle the debugger

## REPL Commands (type these in the debugger)
    = 'expression'
      Use this to prepend 'return' on an expression or statement to allow
      printing of the results
    =clear (not implemented)
      Use this while entering a multi-line statement to clear it and return to
      normal edit mode

## Debug Console
The debug console displays any debug messages that meet or exceed its log
level threshold.  Current defaults include Info < Notice < Warn < Error, but
as the level is just an integer, you can use your own schema.

Note that displayed messages are not buffered.  If your log level is 'notice'
and an 'info' message is passed, it will not be displayed.  Lowering the log
threshold will not display that message, and conversely, raising it will not
cause old messages that do not meet the new threshold to disappear.

(Currently unable to change log level except by editting the text file.)

## REPL
Though the REPL operates pretty much how one would expect a REPL to operate,
there are a few things to keep in mind.

### Environment
The default environment is the root/global environment.  I am still
investigating whether it is feasible or even possible to implement an actual
debugger.  Since we have setfenv, changing the environment/scope of the REPL
is easy.  However, we lack coroutines and I haven't found a good way to
interrupt execution and wait for input, but not block game execution.  If I
am able to overcome that limitation, we'll still be limited to functions that
run post initialization (post ADDON_LOADED event) as we won't have a UI prior
to that.

### Return Values
Any LUA statement (single or multi-line) will be evaluated, and any returned
results will be displayed. For instance, the statement

    local a = 5

will create a local variable in the current context with the value of 5, but
nothing will display.  If you then enter the statement

    return a

the value of the local you just created will be returned and you will see "5"
displayed.  As a shorthand for prepending 'return' on an expression, you can
simply type '='.  For instance,

    = 5

would be the same as typing

    return 5

which would display '5' in the results on the debug console.

#### Multi-line Statements
Warning:  These are still very buggy.

Any incomplete statement will begin a multi-line statement, thus entering

    function foo()

will start a multi-line statement which will continue to accept input until
the statement is completed by entering

    end

If you are in the middle of a multi-line statement and don't wish to complete
it, simply enter

    =clear (not yet implemented)
