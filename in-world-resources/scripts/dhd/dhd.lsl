/*  Ida Stargate network
    Copyright (C) 2023  Kim Lindgren/Kim Hester (Real/SL)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

integer showingText = FALSE;

default {
    on_rez(integer param) {
        llResetScript();
    }
    
    state_entry() {
        llListen(-12444, "", NULL_KEY, "");
    }
    
    touch_start(integer num) {
        if(!showingText) {
            llMessageLinked(LINK_ALL_OTHERS, 0, "show-text", NULL_KEY);
        } else {
            llMessageLinked(LINK_ALL_OTHERS, 0, "hide-text", NULL_KEY);
        }
        
        showingText = !showingText;
    }

    listen(integer channel, string name, key id, string message) {
        list cmd = llParseString2List(message, ["|"], []);
        
        if(llList2String(cmd, 0) == "lock-chevron") {
            llMessageLinked(LINK_ALL_OTHERS, 0, "button-lock", llList2String(cmd, 2));
        } else if(llList2String(cmd, 0) == "ev-activation") {
            llMessageLinked(LINK_ALL_OTHERS, 0, "button-lock", "center");
        } else if(llList2String(cmd, 0) == "gate-reset") {
            llMessageLinked(LINK_ALL_OTHERS, 0, "button-reset", NULL_KEY);
        }
    }
    
    link_message(integer sender_num, integer num, string str, key id) {
        if(id == "center") {
            llSay(-12444, "dial-symbols");
        } else if(id == "center-deactivate") {
            llSay(-12444, "shutdown");
        } else {
            llSay(-12444, "symbol|" + (string)id);
        }
    }
}
