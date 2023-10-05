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

activateButton() {
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW, ALL_SIDES, 0.3]); 
    llPlaySound("80c055ba-3d32-b740-15a4-eaf76f42f4b3", 1.0);
}

resetButton() {
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW, ALL_SIDES, 0.0]);
}

default {
    state_entry() {
        resetButton();
    }
    
    touch_start(integer num) {
        llMessageLinked(LINK_ROOT, 0, "button-pressed", llGetObjectDesc());
        activateButton();   
    }
    
    link_message(integer sender_num, integer num, string str, key id) {    
        if((string)id == llGetObjectDesc() & str == "button-lock") {
            activateButton();
        } else if(str == "button-reset") {
            resetButton();
        } else if(str == "show-text") {
            llSetText(llGetObjectDesc(), <255, 255, 255>, 1);   
        } else if(str == "hide-text") {
            llSetText("", <255, 255, 255>, 1);    
        }
    }
}
