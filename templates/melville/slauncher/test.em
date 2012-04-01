
system.require('appGui.em');
system.require('std/core/simpleInput.em');
system.require('std/core/repeatingTimer.em');
//get name before beginning

var a = new std.core.RepeatingTimer(3,repTimerFunc);

function repTimerFunc(repTimer)
{
    if (std.core.SimpleInput.ready())
    {
        repTimer.suspend();

        var newInput = std.core.SimpleInput(
            std.core.SimpleInput.ENTER_TEXT,
            'Enter username for Melville',
            function(username)
            {
                mApps = new AppGui(username);
            });
    }
}
