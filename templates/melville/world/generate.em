system.require('std/scriptingGui/fileReceiver.em');
system.require('std/movement/movable.em');
system.require('std/movement/animatable.em');

scriptable = new std.script.Scriptable();
movable = new std.movement.Movable();
animatable = new std.movement.Animatable();

system.__debugPrint('\n\nGot into generate.em\n\n');

system.onPresenceConnected(
    function(pres, clearCallback) {
        clearCallback.clear();

        var meshes = [
             {
                 'mesh': "meerkat:///kittyvision/house19.dae/optimized/house19.dae",
                 'scale': 10
             },
             {
                 'mesh': "meerkat:///kittyvision/house20.dae/optimized/house20.dae",
                 'scale': 10
             },
             {
                 'mesh': "meerkat:///kittyvision/house21.dae/optimized/house21.dae",
                 'scale': 10
             },
             {
                 'mesh': "meerkat:///kittyvision/house17.dae/optimized/house17.dae",
                 'scale': 10
             },
             {
                 'mesh': "meerkat:///kittyvision/house23.dae/optimized/house23.dae",
                 'scale': 10
             }
        ];
        for(var x = 0; x < 100; x++) {
            system.timeout(
                5 + x/5,
                std.core.bind(
                    function(x) {
                        var mesh = meshes[ Math.floor(Math.random() * meshes.length) ];
                        var footprint = 20;
                        system.createPresence(
                            {
                                // Signs are setup so zero rotation on avatar at origin puts this in view
                                'pos': < -(x%10) * footprint, 50, -Math.floor(x/10) * 30>,
                                'mesh': mesh['mesh'],
                                'scale': mesh['scale'],
                                'physics': '{"treatment":"vertical_dynamic", "bounds":"box"}'
                            }
                        );
                    },
                    undefined, x
                )
            );
        }
    }
);
