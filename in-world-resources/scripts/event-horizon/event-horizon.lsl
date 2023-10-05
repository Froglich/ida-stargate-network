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

string region = NULL_KEY;
vector coordinates = ZERO_VECTOR;
integer listen_channel = -1234; 

default
{
    state_entry() {
        llSetTextureAnim(ANIM_ON | LOOP | PING_PONG, ALL_SIDES, 4, 4, 0, 0, 24.0);
        llVolumeDetect(TRUE);
    }

    on_rez(integer param) {
        listen_channel = param;
        llListen(listen_channel, "", NULL_KEY, "");
        llPlaySound("1cecee5f-e658-a19e-e71f-aab9f31e9a7d", 1.0);
        llSetTextureAnim(ANIM_ON, ALL_SIDES, 4, 4, 0, 0, 24.0);
        llSetTexture("a2ba84d3-fcec-f51c-65a2-a8a9496a0af6", ALL_SIDES);
        llSleep(0.5);
        llSetTextureAnim(ANIM_ON | LOOP, ALL_SIDES, 4, 4, 0, 0, 24.0);
        llSetTexture("6b882b33-72bf-f8a7-3096-d495107d3529", ALL_SIDES);
        llSay(listen_channel, "event-horizon-ready");
        llMessageLinked(LINK_THIS, 0, "particles", "");
        llSetTimerEvent(4.2);
    }
    
    touch_start(integer total_number) {
        if(coordinates != ZERO_VECTOR & region != NULL_KEY) {
            llMapDestination(region, coordinates, ZERO_VECTOR);
        }
    }
    
    listen(integer channel, string name, key id, string message) {
        list details = llParseString2List(message, ["|"], []);
        
        if(message == "die") {
            llPlaySound("aaffc706-4d9a-230b-3265-e53654371901", 1.0);
            llSetTextureAnim(ANIM_ON | REVERSE, ALL_SIDES, 4, 4, 0, 0, 24.0);
            llSetTexture("a2ba84d3-fcec-f51c-65a2-a8a9496a0af6", ALL_SIDES);
            llSleep(0.5);
            llSetTexture(TEXTURE_TRANSPARENT, ALL_SIDES);
            llSleep(2.5);
            llDie();
        } if(llGetListLength(details) != 2) {
            return;
        }
        
        region = llList2String(details, 0);
        coordinates = (vector)llList2String(details, 1);
    }
    
    collision_start(integer num) {
        llMessageLinked(LINK_ALL_OTHERS, 0, "shlorp", NULL_KEY);
    }
    
    timer() {
        llLoopSound("9890451f-5e9d-253a-3a7d-a630c7565954", 1.0);
        llSetTimerEvent(0);
    }
}
