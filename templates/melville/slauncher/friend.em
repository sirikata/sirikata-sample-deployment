
system.require('imUtil.em');
system.require('convGUI.em');


(function()
{
    //constants
    var REGISTRATION               =  0;
    var CONNECTED_CONV             =  1;
    var OTHER_SIDE_NON_RESPONSIVE  =  2;
    
    
    var REGISTRATION_TIMEOUT       = 500;
    var MESSAGE_TIMEOUT            =  50;


    /**
     @param{String-tainted} name - Self-reported name of the friend
     that will appear in friend's list.
 
     @param{Visible} vis - Visible object corresponding to presence of
     friend.

     @param{ApplicationGUI} appGui - Gui object for application.  @see
     appGui.em.  If this is a room coordinator friend, then appGui is
     a Room object.  @see room.em.  Room objects implement all the
     same behaviors as AppGui objects.

     @param{unique int} imID - Each friend has a unique id associated
     with it.

     @param {ConvGUI,undefined} convGUI - This value may be
     undefined.  In these instances, create own gui.  @see convGUI.em.
     Note a Room object (@see room.em) may be passed in as well.  Room
     objects implement all the same behaviors as ConvGUI objects.

     @param {int} roomFriendType - @see Friend.RoomType.  If
     communicating with another directly (ie, not in a chat room, then
     has type Peer).  If you control the room, then you are a
     RoomCoordinator.  If you are subscribed to the room, then you are
     a RoomReceiver.
     
     Each friend sends imID to friend and sets up handlers listening
     for those imIDs

     @param {int/null} friendID - If not null, then set to the id that
     the friend has reported for this connection.  (ie, the mID field
     of a message received from other connection.
     */
    Friend = function(name, vis, appGui, imID, convGUI,roomFriendType,friendID)
    {
        //how the friend name will be displayed on the friend's list.
        this.name       = IMUtil.htmlEscape(name);
        this.vis        = vis;
        this.appGui     = appGui;

        //starts out not in a conversation with friend
        this.convGUI    = null;
        if (typeof(convGUI) != 'undefined')
            this.convGUI = convGUI;


        this.roomFriendType = roomFriendType;

        if (typeof(roomFriendType) == 'undefined')
        {
            throw new Error('\n\nGot an undefined room type in Friend.\n\n');
        }
        
        //friendID: note maybe could just use the visible id.
        this.imID       = imID;
        
        this.statusToFriend = "Default status";
        this.statusFromFriend  = "Registering";

        this.profileToFriend = "Default profile";
        this.profileFromFriend = "Registering";

        //every message that we send to friend should have their
        //friendID expliclty included (helps distinguish direct
        //messages from room messages).
        this.friendID = friendID;

        this.topicsDiscussed = [];

        this.appGui.display(this.imID);

        //connection status        
        this.connStatus = REGISTRATION;
        this.beginRegistration();
        this.setupMessageListeners();
    };

    //
    Friend.RoomType = {
            Peer: 1,
            RoomCoordinator: 2,
            RoomReceiver: 3
    };
    
    /**
     Send a message to friend that my profile has changed.  Listeners
     for these messages are set up in @see setupMessageListeners.
     */
    Friend.prototype.updateProfileToFriend = function(newProf)
    {
        this.profileToFriend = newProf;
        if (this.connStatus == CONNECTED_CONV)
            {'imProf':newProf, 'friendID': this.friendID } >> this.vis >> [];
    };


    /**
     Send a message to friend that my status has changed.  Listeners
     for these messages are set up in @see setupMessageListeners.
     */
    Friend.prototype.updateStatusToFriend = function(newStatus)
    {
        this.statusToFriend = newStatus;
        if (this.connStatus == CONNECTED_CONV)
        {
            {'imStatus':newStatus,
             'friendID': this.friendID } >> this.vis >> [];                
        }

    };


    

    /**
     @param {string - untainted} newName
     Changes friend's name to newName
     */
    Friend.prototype.changeName = function(newName)
    {
        this.name = newName;
        if (this.convGUI !== null)
            this.convGUI.changeFriendName(newName);                


    };
    
    /**
     @param {message object} msg from sender corresponding to this.vis.
     Replies with a message that should satisfy regResponseMsg.
     */
    Friend.prototype.processRegReqMsg = function (msg)
    {
        this.friendID = msg.mID;

        //lkjs;
        var replyPart = {
            'status':  this.statusToFriend,
            'profile': this.profileToFriend,
            'friendID': this.friendID
        };
        msg.makeReply(replyPart) >> [];

        //to ensure that we don't infinitely send registration
        //messages.
        if (this.connStatus != CONNECTED_CONV)
            this.beginRegistration();
    };


    /**
     Called when do not receive a response for a registration message
     from within @see Friend.prototype.beginRegistration.
     */
    function noRegResponse()
    {
        //takes care of case where we send two registration requests
        //(the second after receiving one from the other side), and
        //the first request times out.
        if (this.connStatus != CONNECTED_CONV)
        {
            this.connStatus = OTHER_SIDE_NON_RESPONSIVE;
            this.appGui.display(this.imID);                
        }
    }


    /**
     Called when receive a response for a registration message from
     within @see Friend.prototype.beginRegistration.
     */
    function regResponse(msg,sender)
    {
        if (regResponseMsg(msg))
        {
            //registration response message was correctly formatted
            //and accepted.
            this.connStatus = CONNECTED_CONV;
            this.statusFromFriend = IMUtil.htmlEscape(msg.status);
            this.profileFromFriend = IMUtil.htmlEscape(msg.profile);
            this.appGui.display(this.imID);
        }
        else
        {
            //if cannot parse message as a registration response, or
            //if registration was declined, then
            //just treat as if we got no registration response.
            var wrappedNoRegResponse = std.core.bind(noRegResponse,this);
            wrappedNoRegResponse();                
        }
    }

    
    /**
     Helper function that returns true if the msg received is
     correctly formatted with status and profile fields that are
     strings.  Otherwise, returns false.  Called from @see
     Friend.prototype.beginRegistration.
     */
    function regResponseMsg(msg)
    {
        return ((typeof(msg.status) == 'string') &&
                (typeof(msg.profile) == 'string'));
    }

    
    /**
     Sends registration request to other side.  If do not receive a
     response from the other side within time period, connStatus
     transitions from REGISTRATION to OTHER_SIDE_NON_RESPONSIVE.

     If receive a reg accepted response, then update status, etc. of
     other side with info from that message.
     */
    Friend.prototype.beginRegistration = function()
    {

        var wrappedNoRegResponse = std.core.bind(
            noRegResponse,this);

        var wrappedRegResponse = std.core.bind(
            regResponse,this);


        { 'imRegRequest': 1, 'mID': this.imID,
          'roomType': this.roomFriendType, 'friendID': this.friendID,
          'myName': this.appGui.myName}
            >> this.vis >>
            [ wrappedRegResponse, REGISTRATION_TIMEOUT, wrappedNoRegResponse];
    };


    /**
     Returns true if friend is in a state where he/she can send.
     */
    Friend.prototype.canSend = function ()
    {
        return (this.connStatus == CONNECTED_CONV);
    };

    
    
    /**
     If do not already have a convGUI object for this friend, create
     one.  Otherwise, do nothing.
     */
    Friend.prototype.beginConversation = function()
    {
        if (this.convGUI === null)
            this.convGUI = new ConvGUI(this.name,this);                                
    };
    
    
    /**
     Called when we send a chat message to a friend, and the friend
     does not acknowledge it.  Called from @see
     Friend.prototype.msgToFriend.
     */
    function msgUnacked(msgToSend)
    {
        if (this.convGUI !== null)
        {
            this.convGUI.warn('Message: "' +
                              IMUtil.htmlEscape(msgToSend) +
                              '" went undelivered.  Friend'+
                              ' is no longer available.'
                             );
        }
        else
        {
            this.appGui.warn('Some messages to ' + this.name +
                             ' may not have been delivered.');
        }
        this.status = OTHER_SIDE_NON_RESPONSIVE;
        this.appGui.display(this.imID);
    }

    

    /**
     @param {String} msgToSend: tainted.  Need to de-taint before
     sending.

     @param {String} msgFrom : stringified version of visible id.
     Required if friedn is a room coordinator.  Optional otherwise.
     
     Regardless of the state of the connection between self and
     friend, tries to set up
     */
    Friend.prototype.msgToFriend = function(msgToSend, msgFrom)
    {
        if (this.roomType == Friend.RoomType.RoomCoordinator)
        {
            if (typeof(msgFrom) != 'string')
            {
                throw new Error ('\n\nError in msgToFriend. ' +
                                'Should have specified msgFrom as string.');
            }
        }
        
        if ((this.connStatus == OTHER_SIDE_NON_RESPONSIVE) ||
            (this.connStatus == REGISTRATION))
        {
            var warnMsg = 'Cannot message ' + this.name;
            warnMsg += (this.connStatus == REGISTRATION) ?
                ' until your connection is registered.' :
                ' when he/she is offline.';
        
            this.appGui.warn(warnMsg);
            return;
        }


        //if we do not already have a pre-existing conversation, then
        //create a conversation gui
        if (this.convGUI === null)
            this.convGUI = new ConvGUI(this.name,this);                


        //output to the conversation gui.
        this.convGUI.writeMe(IMUtil.htmlEscape(msgToSend));

        var wrappedMsgUnacked = std.core.bind(
            msgUnacked,this,msgToSend);
        
        //send the message to the other side & output it to
        //conversation gui
        {'imMsg': msgToSend, 'friendID': this.friendID, 'sender': msgFrom} >>
            this.vis >>
            [ function(){},MESSAGE_TIMEOUT,wrappedMsgUnacked];

    };

    /**
     */
    Friend.prototype.kill = function()
    {
        this.appGui.remove(this.imID);
    
        if (this.msgHandler !== null )
        {
            this.msgHandler.clear();
            this.msgHandler = null;
        }

        if (this.statusUpdateHandler !== null)
        {
            this.statusUpdateHandler.clear();
            this.statusUpdateHandler = null;
        }

        if (this.profUpdateHandler !== null)
        {
            this.profUpdateHandler.clear();
            this.profUpdateHandler = null;
        }

        if (this.chatListHandler !== null)
        {
            this.chatListHandler.clear();
            this.chatListHandler = null;
        }
        
    };

    /**
     Called when receive a message to display from friend from @see
     Friend.prototype.setupMessageListeners.

     Note that, depending if 
     */
    function handleMessage(msg,sender)
    {
        var senderName = null;
        if (this.roomFriendType  == Friend.RoomType.RoomReceiver)
        {
            //sender should be string-ified version of 
            if ('sender' in msg)
            {
                senderName =this.appGui.getFriendName(msg.sender);
                if (senderName === null)
                    senderName = msg.sender;
            }
        }

        
        if (typeof(msg.imMsg) != 'string')
            return;
            
        //if we've put this friend into an invisible group, do nothing.
        if (!this.appGui.getIsVisibleTo(this.imID))
            return;
            
        //If we don't already have a conversation gui, create one.
        if (this.convGUI === null)
            this.convGUI = new ConvGUI(this.name,this);
            
        //output to the conversation gui.
        this.convGUI.writeFriend(IMUtil.htmlEscape(msg.imMsg),this,senderName);

        //send ack back to other side.
        msg.makeReply({'imMsgAck': 1}) >> [];
    }

    /**
     What to do when receive a status message from friend; called
     from @see Friend.prototype.setupMessageListeners.
     */
    function handleStatusMessage(msg,sender)
    {
        if (typeof(msg.imStatus) != 'string')
            return;

        this.statusFromFriend = msg.imStatus;
        this.appGui.display(this.imID);
    }


    /**
     Called when receive a profile update from friend; called
     from @see Friend.prototype.setupMessageListeners
     */
    function handleProfMessage(msg,sender)
    {
        if (typeof(msg.imProf) != 'string')
            return;

        this.profileFromFriend = msg.imProf;
        this.appGui.display(this.imID);
    }


    function handleChatListMessage(msg,sender)
    {
        if (this.roomFriendType != Friend.RoomType.RoomReceiver)
        {
            IMUtil.dPrint('\nError: got chat list message for a ' +
                          'non-room receiver.');
            return;
        }

        //set the chat participants to their known names:
        for (var s in msg.imChatList)
        {
            var friendName = this.appGui.getFriendName(
                msg.imChatList[s]);

            if (friendName !== null)
                msg.imChatList[s] = friendName;
        }
        
        if (this.convGUI === null)
            this.convGUI = new ConvGUI(this.name,this);
        
        this.convGUI.setChatParticipants(msg.imChatList);
    }


    /**
     @param {array} chatList - Each element is the to-stringed version
     of a visible's identifier.

     Should only be called by a room coordinator and only when this
     Friend is in a canSend state.
     */
    Friend.prototype.sendChatList = function (chatList)
    {
        if (this.roomFriendType != Friend.RoomType.RoomCoordinator)
        {
            IMUtil.dPrint('\n\nError in sendChatList.  Only room ' +
                          'coordinators can send chat list messages.');
            return;
        }


        if (!this.canSend())
        {
            IMUtil.dPrint('\nError in sendChatList.  Room coordinator ' +
                          'was not in sendable state.');
            return;
        }

        //replace my vis id with
        var index = null;
        for (var s in chatList)
        {
            if (chatList[s] == this.vis.toString())
            {
                index = s;
                chatList[s] = 'me';
                break;
            }
        }

        
        //craft and send the message.
        var msgToSend = {
            'imChatList': chatList
        };

        msgToSend >> this.vis >> [];

        if (index != null)
            chatList[index] = this.vis.toString();
    };
    
    /**
     Sets up listeners for profile changes, status changes, and
     regular conversation messages.
     */
    Friend.prototype.setupMessageListeners = function()
    {
        //handler for receiving conversation messages
        var wrappedHandleMessage = std.core.bind(
            handleMessage,this);
        
        this.msgHandler = wrappedHandleMessage <<
            [{'imMsg'::},{'friendID':this.imID:}] << this.vis;
        

        //handler for status updates
        var wrappedHandleStatusMessage = std.core.bind(
            handleStatusMessage,this);
    
        this.statusUpdateHandler = wrappedHandleStatusMessage <<
            [{'imStatus'::}, {'friendID':this.imID:}] << this.vis;

        //handler for profile updates
        var wrappedHandleProfMessage = std.core.bind(
            handleProfMessage,this);
        
        this.profUpdateHandler = wrappedHandleProfMessage <<
            [{'imProf'::},{'friendID':this.imID:}] << this.vis;

        //handler for listening for chat participant messages (if room receiver)
        if (this.roomFriendType == Friend.RoomType.RoomReceiver)
        {
            var wrappedHandleChatListMessage = std.core.bind(
                handleChatListMessage,this);
            
            this.chatListHandler = wrappedHandleChatListMessage <<
                [{'imChatList'::}] <<this.vis;
        }
        else
        {
            this.chatListHandler = null;
        }
    };
    
})();

