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

lockChevron() {
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW, 1, 0.5]); 
    llPlaySound("953aa80c-8dab-a747-de58-684133997185", 1.0);
}

resetChevron() {
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW, 1, 0.0]);
}

default {
    state_entry() {
        lockChevron();
        llSleep(0.5);
        resetChevron();
    }
    
    link_message(integer sender_num, integer num, string str, key id) {    
        if((string)id == llGetObjectDesc() & str == "chevron-lock") {
            lockChevron();
        } else if(str == "chevron-reset") {
            resetChevron();
        }
    }
}
