
system.require('imUtil.em');

(function()
 {
     var WRITE_ME_EVENT           =           'WRITE_ME_EVENT';
     var WRITE_FRIEND_EVENT       =       'WRITE_FRIEND_EVENT';
     var WARN_EVENT               =               'WARN_EVENT';
     var CHANGE_FRIEND_NAME_EVENT = 'CHANGE_FRIEND_NAME_EVENT';
     var NAME_LIST_EVENT          =   'CHANGE_NAME_LIST_EVENT';
     
     function guiName(friendName)
     {
         return 'Messaging with '+ friendName;
     }
     
     
     /**
      @param {string} name
      @param {Friend} friend
      */
     ConvGUI = function(name,friend)
     {
         IMUtil.dPrint('\nGot into conv gui constructor.\n');
         this.friendName = name;
         this.friend = friend;
         this.uiID = IMUtil.getUniqueInt();
         this.guiInitialized = false;
         this.pendingEvents = [];
         this.guiMod = simulator._simulator.addGUITextModule(
             guiName(name),
             getGUIText(name,this),
             std.core.bind(guiInitFunc,this)
         );
     };


     /**
      */
     ConvGUI.prototype.setChatParticipants = function(nameList)
     {
         if (! this.guiInitialized)
         {
             this.pendingEvents.push([NAME_LIST_EVENT , nameList]);
             return;
         }
         internalSetChatParticipants(this,nameList);
     };
     
     /**
      @param {string -- untainted} warnMsg
      */
     ConvGUI.prototype.warn = function(warnMsg)
     {
         if (!this.guiInitialized)
         {
             this.pendingEvents.push([WARN_EVENT,warnMsg]);
             return;
         }
         internalWarn(this,warnMsg);
     };

     /**
      Called when user enters text into tab that needs to be displayed.
      */
     ConvGUI.prototype.writeMe = function(toWrite)
     {
         if (!this.guiInitialized)
         {
             this.pendingEvents.push([WRITE_ME_EVENT,toWrite]);
             return;
         }
         internalWriteMe(this,toWrite);
     };

     /**
      Called when friend enters text into tab that needs to be displayed.
      */
     ConvGUI.prototype.writeFriend = function(toWrite,friend,senderName)
     {
         if (!this.guiInitialized)
         {
             this.pendingEvents.push([WRITE_FRIEND_EVENT,toWrite,senderName]);
             return;
         }
         internalWriteFriend(this,toWrite,senderName);
     };


     ConvGUI.prototype.changeFriendName = function(newFriendName)
     {
         if (!this.guiInitialized)
         {
             this.pendingEvents.push([CHANGE_FRIEND_NAME_EVENT,newFriendName]);
             return;
         }

         internalChangeFriendName(this,newFriendName);
     };
     
     
     /**
      Gets called by js display code when user enters data.  Already
      bound in guiInitFunc to convGUI.
      */
     function userInput(whatWrote)
     {
         this.friend.msgToFriend(whatWrote);
     }

     /**
      Bound in @see ConvGui function, and called by gui when it's been
      initialized.
      */
     function guiInitFunc()
     {
         //gets called when user enters text
         this.guiMod.bind('userInput',std.core.bind(userInput,this));

         //clear all pending events that didn't occur until gui was created.
         this.guiInitialized = true;
         for (var s in this.pendingEvents)
         {
             if(this.pendingEvents[s][0] == WRITE_ME_EVENT)
                 internalWriteMe(this,this.pendingEvents[s][1]);
             else if (this.pendingEvents[s][0] == WRITE_FRIEND_EVENT)
                 internalWriteFriend(this,this.pendingEvents[s][1],this.pendingEvents[s][2]);
             else if (this.pendingEvents[s][0] == CHANGE_FRIEND_NAME_EVENT)
                 internalChangeFriendName(this,this.pendingEvents[s][1]);
             else
                 internalWarn(this,this.pendingEvents[s][1]);
         }
         this.pendingEvents = [];
     }

     //create unique function names
     function constructWarnFuncName(convGUI)
     {
         return 'melville_conv_gui_warn__' + convGUI.uiID.toString();
     }

     function constructWriteFriendFuncName(convGUI)
     {
         return 'melville_conv_gui_write_friend__' + convGUI.uiID.toString();
     }

     function constructWriteMeFuncName(convGUI)
     {
         return 'melville_conv_gui_write_me__' + convGUI.uiID.toString();
     }
     
     function constructChangeFriendFuncName(convGUI)
     {
         return 'melville_conv_gui_change_name__' + convGUI.uiID.toString();
     }

     function constructSetChatParticipantsName(convGUI)
     {
         return 'melville_conv_gui_chat_participants___' + convGUI.uiID.toString();
     }
     
     
     /**
      @param {string-untainted} toWarnWith
      */
     function internalWarn(convGUI,toWarnWith)
     {
         convGUI.guiMod.call(constructWarnFuncName(convGUI),toWarnWith);
     }

     
     function internalSetChatParticipants(convGUI,nameList)
     {
         convGUI.guiMod.call(constructSetChatParticipantsName(convGUI),nameList);
     }

     
     
     /**
      @param {string-untainted} message
      */
     function internalWriteFriend(convGUI,message,sender)
     {
         if (sender == null)
             sender = convGUI.friendName;

         convGUI.guiMod.call(constructWriteFriendFuncName(convGUI),message,sender);
     }

     /**
      @param {string-untainted} message
      */
     function internalWriteMe(convGUI,message)
     {
         convGUI.guiMod.call(constructWriteMeFuncName(convGUI),message);
     }

     /**
      @param {string-untainted} newName
      */
     function internalChangeFriendName(convGUI,newName)
     {
         convGUI.guiMod.call(constructChangeFriendFuncName(convGUI),newName);
     }


     function getGUIText(friendName,convGUI)
     {
         var returner = "sirikata.ui('" + guiName(friendName) + "',";
         returner += 'function(){ ';


         returner += 'var FRIEND_NAME  = "'+friendName+'";';

         //initializing several functions that will return unique
         //values for each convGUI.  This way, can have multiple
         //convGUIs open at once without conflict.


         //history text id
         returner += 'var getMelvilleHistoryID = function() { return ';
         returner += '"history__' + convGUI.uiID.toString() + '";};';

         //text area for melville input id
         returner += 'var getMelvilleTareaID = function(){ return ';
         returner += '"melvilletraea__'+convGUI.uiID.toString() + '";};';

         returner += 'var getMelvilleChatParticipantsID = function(){ return ';
         returner += '"melvilletchat_parts__'+convGUI.uiID.toString() + '";};';
     
         //chat button id
         returner += 'var getMelvilleChatButtonID = function(){ return ';
         returner += '"melvilleChatButton__' + convGUI.uiID.toString() + '";};';

         //melville dialog id
         returner += 'var getMelvilleDialogID = function(){ return ';
         returner += '"melvilleDialogID__' + convGUI.uiID.toString() + '";};';
         
         
         //fill in guts of function to execute for gui module
         returner += @

         //some constants used for display
         var ME_NAME      = 'me';
         var SYS_NAME     = 'system';

         var ME_COLOR     = 'red';
         var FRIEND_COLOR = 'blue';
         var SYS_COLOR    = 'green';


         //actual window code
         $('<div>' +

     '<table><tr><td>' +
              '<div id=' + getMelvilleHistoryID() + ' style="height:200px;width:250px;font:16px/26px Georgia, Garamond, Serif;overflow:scroll;">' +
              //'<div id=' + getMelvilleHistoryID() + ' style="height:120px;width:250px;font:16px/26px Georgia, Garamond, Serif;overflow:scroll;">' +
              '</div>' + //end history
              '<input value="" id=' + getMelvilleTareaID() + ' style="width:250px;">' +          
              '</input>' +


     '</td><td>' +
         '<div id=' +getMelvilleChatParticipantsID() + '>' +
         '</div>' +
         '</td></tr></table>' +
     
              '<button id=' + getMelvilleChatButtonID() + '>Enter</button>' +
          
          '</div>' //end div at top.
          ).attr({id: getMelvilleDialogID(),title:'melville'}).appendTo('body');

         var melvilleWindow = new sirikata.ui.window(
            '#' + getMelvilleDialogID(),
            {
                autoOpen: false,
                height: 'auto',
                width: 300,
                height: 400,
                position: 'right'
            }
         );

         //call this on shift+enter event and also when user hits
         //submit: just transfers message to emerson so that emerson
         //can send it to other listeners.
         var submitUserTextToEmerson = function()
         {
             sirikata.event('userInput',$('#' + getMelvilleTareaID()).val());
             $('#' + getMelvilleTareaID()).val('');
         };
         
         sirikata.ui.button('#' + getMelvilleChatButtonID()).click(
             submitUserTextToEmerson);

         melvilleWindow.show();

         
         //appends the string to the end of the scrolling chat log.
         var writeToLog = function (msgToWrite)
         {
             $('#' + getMelvilleHistoryID()).append(msgToWrite + '<br />');
             //in case user had previously closed the window.
             //auto-scrolls to end of conversation.
             var objDiv = document.getElementById(getMelvilleHistoryID());
             objDiv.scrollTop = objDiv.scrollHeight;
             melvilleWindow.show();
         }
         @;

         //internal to gui display
         returner += constructWriteMeFuncName(convGUI) + '=';
         returner += @
         function(msg)
         {
             var formattedMsg = "<font color=ME_COLOR> "
                 + ME_NAME + "</font>: " + msg;
             
             writeToLog(formattedMsg);
         };
         @;

     returner += constructSetChatParticipantsName(convGUI) + '=';
     returner += @function(nameList)
     {
         var strToDisplay = '<b> Others in room</b><br/>';
         for (var s in nameList)
         {
             strToDisplay += nameList[s] + ' <br/>';
         }

         $('#' + getMelvilleChatParticipantsID()).html(strToDisplay);
     };
     @

     
         //internal to gui display
         returner += constructWriteFriendFuncName(convGUI) + '=';
         returner += @ function(msg,sender)
         {
             var formattedMsg = "<font color=FRIEND_COLOR> "
                 + sender + "</font>: " + msg;
             
             writeToLog(formattedMsg);
         };
         @
         
         //internal to gui display
         returner += constructWarnFuncName(convGUI) + '=';
         returner += @ function(msg)
         {
             var formattedMsg = "<font color=SYS_COLOR> "
                 + SYS_NAME + "</font>: " + msg;
             
             writeToLog(formattedMsg);
         };
         @;
         
         //updates friend's name in conversation.
         returner += constructChangeFriendFuncName(convGUI) + '=';
         returner += @function(newName)
         {
             FRIEND_NAME = newName;
         };


         //handles shift+enter submitting message to other end
         var handleMelvilleTareaKeyUp = function(evt)
         {
             //13 represents keycode for enter, submits whatever's in
             //the text box if user hits enter.
             if (evt.keyCode == 13)
                 submitUserTextToEmerson();
         };

         //copied from chat.js
         var registerHotkeys = function() {
             var register_area = document.getElementById(getMelvilleTareaID());
             register_area.onkeyup = handleMelvilleTareaKeyUp;
         };
         registerHotkeys();
         @;
         
         
         //closes function passed to sirikata.ui and sirikata.ui.
         returner += '});' ;

         return returner;
     }
     
 })();



