/*  Sirikata
 *  default.em
 *
 *  Copyright (c) 2011, Ewen Cheslack-Postava
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *  * Neither the name of Sirikata nor the names of its contributors may
 *    be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


// A sane, simple, default. Only includes functionality from libraries.
system.require('std/shim/restore/simpleStorage.em');


std.simpleStorage.setScript(
    function()
    {
        system.require('std/shim/restore/persistService.em');
        system.require('std/scriptingGui/fileReceiver.em');
        system.require('std/movement/movable.em');
        system.require('std/movement/animatable.em');
        system.require('std/client/default.em');
        
        scriptable = new std.script.Scriptable();
        movable = new std.movement.Movable(true); // Self only
        animatable = new std.movement.Animatable();
        
        // For convenience in debugging, figuring out who's trying to
        // contact you, etc, while we don't have a UI for it, print
        // out any requests that ask you to
        function(msg, sender) { system.prettyprint('Message from ', sender.toString(), ': ', msg); } << [{'printrequest'::}];

        var init = function() {
            simulator = new std.client.Default(system.self,
                                               function()
                                               {
                                                   system.import('test.em');
                                               });
        };

        if (system.self)
        {
            //already have a connected presence, use it.
            init();
        }
        else if (system.presences.length != 0)
        {
            system.changeSelf(system.presences[0]);
            //already have a connected presence, use it.
            init();
        }
        else
        {
            //if do not have a connected presence
            system.onPresenceConnected(
                function(pres,toClearPresFunction) {
                    init();
                    toClearPresFunction.clear();
                }
            );
        }
    }, true);
