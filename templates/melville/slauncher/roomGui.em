
(function()
 {
     RoomGui = function(rmID,room)
     {
         this.rmID = rmID;
         this.guiInitialized = false;
         this.room = room;
         this.guiMod = simulator._simulator.addGUITextModule(
             guiName(this),
             getRoomGuiText(this),
             std.core.bind(guiInitFunc,undefined,this)
         );

         system.__debugFileWrite(getRoomGuiText(this),'testRoomGui.em');
     };


     /**
      Creates a list of friends that are in the room and a list that
      are outside it.  Returns each of these lists to gui part of the
      application.  Each list has elements with the following format:
      elem 1: [friendName_1, friendID_1]
      elem 2: [friendName_2, friendID_2]
      ...
      */
     function requestMembershipDialogEmerson(roomGui)
     {
         IMUtil.dPrint('\n\nGot into requestMembershipDialogEmerson function\n\n');
         
         //find list of friends that are already in the room:
         var inRoom = {};
         for (var s in roomGui.room.friendMap)
         {
             var friend = friendMap[s];
             inRoom[friend.imID] = [friend.name,friend.imID];
         }

         
         //find list of friends that are not already in room:
         var notInRoom ={};
         for (var s in roomGui.room.appGui.imIDToFriendMap)
         {
             IMUtil.dPrint('\n\nIn requestMembershipDialogEmerson of roomGui.em: ' +
                           'this check will not actually work: friends ' +
                           'have different ids since they are room ' +
                           'friends or individual friends.\n\n'
                          );

             if (s in inRoom)
                 continue;

             var friend = roomGui.room.appGui.imIDToFriendMap[s];
             notInRoom[friend.imID] = [friend.name, friend.imID];
         }

         //actually pop up a new requestMembershipDialog window in gui.
         roomGui.guiMod.call('requestMembershipDialog',inRoom,notInRoom);
     }
     

     /**
      @param {map<int,int>} added - Keys are the ids of friends that
      have been added to room.  Values do not matter.
      
      @param {map<int,int>} added - Keys are the ids of friends that
      have been removed from room.  Values do not matter.

      Note: added and removed cannot have same members.
      */
     function requestMembershipChange(roomGui,added,removed)
     {
         //add new friends
         for(var s in added)
         {
             if (!(s in roomGui.room.appGui.imIDToFriendMap))
             {
                 IMUtil.dPrint('\nFriend id no longer ' +
                               'available in roomGui.em.');
                 continue;
             }
             
             var friendToAdd = roomGui.room.appGui.imIDToFriendMap[s];
             roomGui.room.addFriend(friendToAdd);
         }

         //remove
         for (var s in removed)
             roomGui.room.removeFriend(s);                 
     }


     function updateOtherRoomInfo(roomGui, name, greetingMessage, loggingAddress)
     {
         IMUtil.dPrint('\n\nGot inot updateOtherRoomInfo.\n\n');
         IMUtil.dPrint('\n\nName: ' + name + '\n\n');
         IMUtil.dPrint('\n\nMessage: ' + greetingMessage + '\n\n');
         IMUtil.dPrint('\n\nLogging: ' + loggingAddress + '\n\n');
         
         roomGui.room.setName(name);
         roomGui.room.setLoggingAddress(loggingAddress);
         //roomGui.room.setGreetingMessage(greetingMessage);
     }
     
     
     function guiInitFunc(roomGui)
     {
         //called when user clicks membership dialog
         var wrappedRequestMembDialogEmerson =  std.core.bind(
             requestMembershipDialogEmerson,undefined,roomGui);
         
         roomGui.guiMod.bind('requestMembershipDialogEmerson',
                             wrappedRequestMembDialogEmerson);


         //called when user finishes changing membership of room.
         var wrappedMembershipChange = std.core.bind(
             requestMembershipChange,undefined,roomGui
         );
         roomGui.guiMod.bind('membershipChange',
                             wrappedMembershipChange);


         //called when user requests to change room name,
         //when user requests that the room performs logging,
         //when user wants to change message sent by room on
         //registration, etc.
         var wrappedUpdateOtherRoomInfo = std.core.bind(
             updateOtherRoomInfo,undefined,roomGui
         );
         roomGui.guiMod.bind('updateOtherRoomInfo',
                            wrappedUpdateOtherRoomInfo);
         
     }

     function guiName(roomGui)
     {
         return 'Room_controller_for_room ' + roomGui.rmID.toString();
     }


     
     function getRoomGuiText(roomGui)
     {
         var name = 'melvilleRoomManagement__' + roomGui.rmID.toString();
         var returner = "sirikata.ui('" + guiName(roomGui)  + "',";
         returner += 'function(){ ';

         returner += 'var roomCtrlDivName = "' + name + '";';
         returner += 'var roomMembershipDivName ="' + name + 'Member";';
         returner += @

         //gui for displaying room controls.
         $('<div>' +

           //allow to change name, message sent, and logging information.
           'room name: <input value="some name" style="width:250px;" id="' +
           getRoomNameTextAreaID() + '"></input> <br/>' + 
           'room message: <input value="I am a room." style="width:250px;" id="' +
           getRoomMessageTextAreaID() + '"></input> <br/>' +
           'room logging: <input value="" style="width:250px;" id="' +
           getRoomLoggingTextAreaID() + '"></input> <br/>' +
           
           '<button id=' + getRoomGuiCharacteristicButtonID() + '> Update </button><br/>' +
           '<button id=' + getMelvilleRoomGuiMembershipID()+'> Change group membership</button>' +
           '</div>' //end div at top.
          ).attr({id:roomCtrlDivName,title:'melvilleRoom'}).appendTo('body');


         function getRoomNameTextAreaID()
         {
             return 'room_name_textarea_'+ roomCtrlDivName;
         }

         function getRoomMessageTextAreaID()
         {
             return 'room_message_text_area_id' + roomCtrlDivName;
         }

         function getRoomLoggingTextAreaID()
         {
             return 'room_logging_text_area_id' + roomCtrlDivName;
         }

         function getRoomGuiCharacteristicButtonID()
         {
             return 'room_gui_characteristic_buttonID_' + roomCtrlDivName;
         }
         
         
         function getMelvilleRoomGuiMembershipID()
         {
             return roomCtrlDivName+'__changeGroupMembershipID';
         }
         
         var roomWindow = new sirikata.ui.window(
            '#' + roomCtrlDivName,
            {
	        autoOpen: false,
	        height: 'auto',
	        width: 300,
                height: 400,
                position: 'right'
            }
         );
         roomWindow.show();

         //executed when change membership button clicked: sends message down
         //to emerson roomGui code 
         sirikata.ui.button('#' + getMelvilleRoomGuiMembershipID()).click(
             function()
             {
                 sirikata.event('requestMembershipDialogEmerson');             
             }
         );
         

         //whenever characteristics button is pressed, send message to
         //underlying emerson code to update room gui with values captured
         //from textareas
         sirikata.ui.button('#' + getRoomGuiCharacteristicButtonID()).click(
             function()
             {
                 var newNameID = getRoomNameTextAreaID();
                 var newMessageID = getRoomMessageTextAreaID();
                 var newLoggingID = getRoomLoggingTextAreaID();


                 var newMessage = $('#' + newMessageID).val();
                 var newLogging = $('#' + newLoggingID).val();
                 var newName = $('#' + newNameID).val();
                 
                 sirikata.event('updateOtherRoomInfo',newName,newMessage,newLogging);
             }
         );

         

         
         //gui for displaying membership controls
         $('<div>' +
           '</div>' //end div at top.
          ).attr({id:roomMembershipDivName,title:'melvilleRoom'}).appendTo('body');

         var membershipWindow = new sirikata.ui.window(
            '#' + roomMembershipDivName,
            {
	        autoOpen: false,
	        height: 'auto',
	        width: 300,
                height: 400,
                position: 'right'
            }
         );
         membershipWindow.hide();


         /**
          \param entry - \see generateInRoomDiv
          */
         function getDivIDMemDialog(entry)
         {
             return 'melville_room_management_div__' +
                 roomCtrlDivName + 
                 entry[1].toString();
         }

         function generateInRoomClassName()
         {
             return 'inRoom_class_melville_'+roomCtrlDivName;
         }

         function generateNotInRoomClassName()
         {
             return 'not_inRoom_class_melville_'+roomCtrlDivName;
         }
         
         /**
          \param {array} entry - first element of entry array is the
          name of the friend, the second is the imID of the friend.

          \param {bool} inRoom - True if the entry is currently in the
          room.  False otherwise.
          
          \return {array} - First element of array is a string
          representing the html for div enclosing this element.  The
          second element is a function to execute after including the
          html the page (binds action to when button is clicked).
          */
         function generateMembershipDiv(entry,inRoom)
         {
             var membDivID = getDivIDMemDialog(entry);
             var newHtml = '';
             newHtml += '<button id="' + membDivID + '" ';
             newHtml += 'class="';
             if (inRoom)
                 newHtml += generateInRoomClassName();
             else
                 newHtml += generateNotInRoomClassName();

             newHtml += '" ';
             newHtml += 'value="' + entry[1] + '" ';
             newHtml += '>';
             newHtml += entry[0];
             newHtml += '</button><br/>';

             var toExecAfter= function()
             {
                 sirikata.ui.button('#' + membDivID).click(
                     function()
                     {
                         //see arguments to melvilleRmMembFuncAddRemove
                         melvilleRmMembFuncAddRemove(entry,!inRoom);
                     }
                 );
             };
             return [newHtml,toExecAfter];
         }

         /**
          param {bool} add - true if we're adding this entry to the
          room, false otherwise.
          */
         function melvilleRmMembFuncAddRemove(entry, add)
         {
             //remove previous entry
             var membDivID = getDivIDMemDialog(entry);
             sirikata.ui.button('#' + membDivID).remove();

             //now add to correct column
             var newEntry = generateMembershipDiv(entry,add);
             if (add)
                 $('#' + generateInRoomTableCellDivID()).append(newEntry[0]);
             else
                 $('#' + generateNotInRoomTableCellDivID()).append(newEntry[0]);

             newEntry[1]();
         }
         
         function generateInRoomTableCellDivID()
         {
             return roomCtrlDivName + '__inRoomTableCellID';
         }

         function generateNotInRoomTableCellDivID()
         {
             return roomCtrlDivName + '__notInRoomTableCellID';
         }


         function getUpdateMembershipButtonID()
         {
             return 'membership_button_submit_id_' +
                 roomCtrlDivName;
         }
         

         /**
          this gets called from the emerson function
          requestMembershipDialogEmerson.

          \param {map: <imID,[entryName,imID]>} inRoom - represents
          all friends that are already in room.

          \param {map: <imID,[entryName,imID]>} inRoom - represents
          all friends that are not already in room.
          */
         requestMembershipDialog = function(inRoom,notInRoom)
         {
             var newHtml = '<table><tr><td width="300">In room</td>' +
                 '<td width="300">Not in room</td></tr>';
             
             newHtml += '<tr><td id="' + generateInRoomTableCellDivID() +
                 '">';

             //after include buttons from generateMembershipDiv in html page,
             //need to execute all functions that bind callbacks to
             //them when their buttons are pressed.  All of these
             //functions should be stored in toExecAfter.  After
             //including all the buttons in the page, run through full
             //toExecAfter array, calling each function.
             var toExecAfter = [];
             for (var s in inRoom)
             {
                 var newEntry = generateMembershipDiv(inRoom[s],true);                     
                 newHtml += newEntry[0];
                 toExecAfter.push(newEntry[1]);
             }

             newHtml+= '</td><td id="' + generateNotInRoomTableCellDivID() +
                 '">';

             for (var s in notInRoom)
             {
                 var newEntry =generateMembershipDiv(notInRoom[s],false);
                 newHtml += newEntry[0];
                 toExecAfter.push(newEntry[1]);
             }
             
             newHtml += '</td></tr></table>';

             newHtml += '<button id="' + getUpdateMembershipButtonID() +'">';
             newHtml += 'commit membership changes';
             newHtml += '</button>';
             
             
             var jqueryMembershipID = '#' + roomMembershipDivName;
             $(jqueryMembershipID).html(newHtml);
             membershipWindow.show();

             for (var s in toExecAfter)
                 toExecAfter[s]();

             
             //must also execute this after setting the html.
             sirikata.ui.button('#' + getUpdateMembershipButtonID()).click(
                 function()
                 {
                     var allInRoom =
                         $('.' + generateInRoomClassName()).toArray();
                     
                     var allNotInRoom =
                         $('.' + generateNotInRoomClassName()).toArray();

                     var added   = {};
                     var removed = {};
                     for (var s in allInRoom)
                     {
                         var addedID = allInRoom[s].value;
                         if (addedID in notInRoom)
                             added[addedID] = addedID;
                         
                     }
                     for (var s in allNotInRoom)
                     {
                         var removedID = allNotInRoom[s].value;
                         if (removedID in inRoom)
                             removed[removedID] = removedID;
                     }

                     
                     sirikata.event('membershipChange',added,removed);
                     
                     //close membershipWindow.
                     membershipWindow.hide();
                 }
             );
             
         };
         @;

         //close the onready function and the sirikata.ui 
         returner += '});'
         return returner;
     }
     
 })();