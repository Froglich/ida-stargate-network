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

integer active = FALSE;

playSound() {
    llPlaySound("8b2c565f-ef9d-4918-ac8e-15b939ed087b", 1.0);
}

activateButton() {
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW, ALL_SIDES, 0.3]); 
    playSound();
    active = TRUE;
}

resetButton() {
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW, ALL_SIDES, 0.0]);
    active = FALSE;
}

default {
    state_entry() {
        resetButton();
    }
    
    touch_start(integer num) {
        if(!active) {
            llMessageLinked(LINK_ROOT, 0, "button-pressed", "center");
            activateButton();   
        } else {
            llMessageLinked(LINK_ROOT, 0, "button-pressed", "center-deactivate");
            playSound();
        }
    }
    
    link_message(integer sender_num, integer num, string str, key id) {    
        if((string)id == llGetObjectDesc() & str == "button-lock") {
            activateButton();
        } else if(str == "button-reset") {
            resetButton();
        }
    }
}
