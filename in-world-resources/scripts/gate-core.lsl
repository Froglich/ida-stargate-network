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

string gateURL = "";
string gateUUID = "";

string networkHost = "ida-gates.eu";
string pendingGateURL = "";
string connectedGateURL = "";

key registerKey = NULL_KEY;
key updateKey = NULL_KEY;
key gateSearchKey = NULL_KEY;
key symbolDialKey = NULL_KEY;
key pendingRequestKey = NULL_KEY;

integer evListener = -1000;
integer evChannel = -1000;
integer menuListener = 1000;
integer menuChannel = 1000;

string targetRegion = NULL_KEY;
string targetVectorString = NULL_KEY;

list symbols = [];

integer currentState = 0; // 0 = inactive, 1 = dialing, 2 = outgoing, 3 = incoming, 4 = delete
list states = ["inactive", "dialing", "outgoing", "incoming", "delete"];

apiSay(string msg) {
    llSay(-12444, msg);   
}

integer randBetween(float min, float max) {
    return 0 - llCeil(llFrand(max - min) + min);
}

registerNewGate(string url) {
    llOwnerSay("Registering with network...");
    gateURL = url;
    
    registerKey = llHTTPRequest(
        "http://" + networkHost + "/register", 
        [HTTP_METHOD, "PUT"],
        url 
    );  
}

setState(integer newState) {
    if(currentState == newState) return;
    
    currentState = newState;
    apiSay("state|" + llList2String(states, currentState));
    
    llHTTPRequest(
        "http://" + networkHost + "/state", 
        [HTTP_METHOD, "PUT"],
        (string)currentState 
    );
}

gateRegistered(string body) {
    llOwnerSay("Registered.");
}

connectToNamedGate(string q) {                            
    gateSearchKey = llHTTPRequest(
        "http://" + networkHost + "/dial?q=" + llEscapeURL(q), 
        [HTTP_METHOD, "GET"],
        ""
    );   
}

dialGate(string msg, integer quick) {
    list details = llParseString2List(msg, ["|"], []);
    
    if(llGetListLength(details) != 9) {
        resetStargate();
        return;
    }
    
    string name = llList2String(details, 0);
    pendingGateURL = llList2String(details, 1);
    string c1 = llList2String(details, 2);
    string c2 = llList2String(details, 3);
    string c3 = llList2String(details, 4); 
    string c4 = llList2String(details, 5);
    string c5 = llList2String(details, 6);
    string c6 = llList2String(details, 7);
    string c7 = llList2String(details, 8);
    
    apiSay("dialing|" + name + "|" + c1 + "|" + c2 + "|" + c3 + "|" + c4 + "|" + c5 + "|" + c6 + "|" + c7);
    
    if(!quick) {
        dialGateSequence(name, c1, c2, c3, c4, c5, c6, c7);
    } else {
        dialGateDirectly();
    }
}

dialGateSequence(string name, string c1, string c2, string c3, string c4, string c5, string c6, string c7) {        
    setState(1);
    llSay(0, "Dialing " + name);
        
    lockChevron("1", c1);
    llSleep(1);
    lockChevron("2", c2);
    llSleep(1);
    lockChevron("3", c3);
    llSleep(1);
    lockChevron("4", c4);
    llSleep(1);
    lockChevron("5", c5);
    llSleep(1);
    lockChevron("6", c6);
    llSleep(1);
    lockChevron("7", c7);
        
    pendingRequestKey = llHTTPRequest(
        pendingGateURL, 
        [HTTP_METHOD, "PUT"],
        "connection-request|" + gateURL + "|" + llGetRegionName()
    );    
}

dialGateDirectly() {
    pendingRequestKey = llHTTPRequest(
        pendingGateURL, 
        [HTTP_METHOD, "PUT"],
        "connection-request|" + gateURL + "|" + llGetRegionName()
    );   
}

lockChevron(string chevron, string symbol) {
    llMessageLinked(LINK_ALL_OTHERS, 0, "chevron-lock", chevron);
    apiSay("lock-chevron|" + chevron + "|" + symbol);
}

resetChevrons() {
    llMessageLinked(LINK_ALL_OTHERS, 0, "chevron-reset", "");
}

parseConnectionReply(string message) {
    list details = llParseString2List(message, ["|"], []);
    
    if(llList2String(details, 0) == "go-ahead" & llGetListLength(details) == 3) {
        targetRegion = llList2String(details, 1);
        targetVectorString = llList2String(details, 2);
        apiSay("ev-activation|outgoing|" + targetRegion + "|" + targetVectorString);
        connectedGateURL = pendingGateURL;
        pendingGateURL = "";
        
        setState(2);
        activateEventHorizon();
    } else {
        resetChevrons();
        setState(0);
    }
}

activateIncomingWormhole(string incomingConnectionName) {
    setState(3);
    resetChevrons();
    llSay(0, "Incoming wormhole from " + incomingConnectionName);
    
    lockChevron("1", "#");
    llSleep(0.25);
    lockChevron("2", "#");
    llSleep(0.25);
    lockChevron("3", "#");
    llSleep(0.25);
    lockChevron("4", "#");
    llSleep(0.25);
    lockChevron("5", "#");
    llSleep(0.25);
    lockChevron("6", "#");
    llSleep(0.25);
    lockChevron("7", "#");
    llSleep(0.25);
    
    activateEventHorizon();
    apiSay("ev-activation|incoming");
}

activateEventHorizon() {    
    killEventHorizon();
    evChannel = randBetween(200, 4000);
    evListener = llListen(evChannel, "", NULL_KEY, "");
    llRezObject("event-horizon", llGetPos(), ZERO_VECTOR, llGetRot(), evChannel);
    llSetTimerEvent(40.0);
}

killEventHorizon() {
    llWhisper(evChannel, "die");
    llListenRemove(evListener);
    llSetTimerEvent(0.0);
}

resetStargate() {
    apiSay("gate-reset");
    killEventHorizon();
    symbols = [];
    llListenRemove(evListener);
    resetChevrons();
    connectedGateURL = "";
    setState(0);
    targetRegion = NULL_KEY;
    targetVectorString = NULL_KEY;
}

handleLocalAPI(string msg, string name, key id) {
    list cmds = llParseString2List(msg, ["|"], []);

    if(llList2String(cmds, 0) == "send-chatter" && llGetListLength(cmds) == 2 && currentState >= 2) {
        llHTTPRequest(
            connectedGateURL, 
            [HTTP_METHOD, "POST"],
            "chatter|" + name + "|" + llList2String(cmds, 1)
        ); 
    } else if(llList2String(cmds, 0) == "symbol" && llGetListLength(cmds) == 2 && currentState < 2) {
        if(llGetListLength(symbols) < 7) {
            string symbol = llList2String(cmds, 1);
            symbols += symbol;
            lockChevron((string)llGetListLength(symbols), symbol);
            setState(1);
        } else {
            apiSay("address-too-long");
            resetStargate();   
        }
    } else if(llList2String(cmds, 0) == "dial-symbols" && currentState < 2 && gateSearchKey == NULL_KEY) {
        if(llGetListLength(symbols) < 7) {
            apiSay("address-too-short");
            resetStargate();
            return;
        }
                
        symbolDialKey = llHTTPRequest(
            "http://" + networkHost + "/dial-address", 
            [HTTP_METHOD, "PUT"],
            "[" + llDumpList2String(symbols, ",") + "]"
        ); 
    } else if(msg == "shutdown" && currentState == 2) {
        closeConnection();   
    }
}

handleRemoteAPI(string msg) {
    list q = llParseString2List(msg, ["|"], []);
            
    if(llList2String(q, 0) == "chatter" && llGetListLength(q) == 3 && currentState >= 2) {
        apiSay(msg);
    }   
}

closeConnection() {
    if(currentState == 2) {
        llHTTPRequest(
            connectedGateURL, 
            [HTTP_METHOD, "PUT"],
            "close-connection"
        );
        resetStargate();
    }
}

Dialog(key id, string text, list menu) {
    llListenRemove(menuListener);
    menuChannel = (integer)llFrand(-922);
    menuListener = llListen(menuChannel, "", id, "");
    menu += "CANCEL";
    llDialog(id, text, menu, menuChannel);
}

default {
    on_rez(integer param) {
        llResetScript();   
    }
    
    state_entry() {
        llRequestURL();
        resetStargate();
        llListen(0, "", NULL_KEY, "");
        llListen(-12444, "", NULL_KEY, "");
    }
    
    changed(integer change) {
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY)) {
            llResetScript();
        }
        if (change & (CHANGED_REGION | CHANGED_REGION_START)) {
            llRequestURL();
        }
    }
    
    http_response(key id, integer status, list meta, string body) {
        if(id == registerKey) {
            if(status == 200) {
                gateRegistered(body);
            } else if(status == 401) {
                llOwnerSay("You have been banned from this stargate network.");
                llDie();
            } else if(status == 404) {
                llOwnerSay("The network is incompatible with this version of the stargate.");
            } else {
                llOwnerSay("The network is experiencing issues.");   
            }
        } else if(id == gateSearchKey) {
            if(status == 200) {
                dialGate(body, FALSE);   
            } else if(status == 401) {
                llSay(0, "This stargate is unable to dial because of its owners missconduct.");
            } else if(status == 404) {
                llSay(0, "No matching gate found");   
            } else {
                llOwnerSay("The network is experiencing issues.");   
            }
        } else if(id == pendingRequestKey) {
            if(status == 200) {
                parseConnectionReply(body);   
            } else if(status == 499) {
                llSay(0, "The connection attempt timed out.");
                resetStargate();
            } else if(status == 404) {
                llSay(0, "That stargate can not be contacted.");
                resetStargate();
            } else {
                llSay(0, "An unexpected error occurred while attempting to connect to that stargate.");
                resetStargate();   
            }
        } else if(id == symbolDialKey) {
            if(status == 200) {
                dialGate(body, TRUE);
            } else if(status == 401) {
                llSay(0, "This stargate is unable to dial because of its owners missconduct.");
            } else if(status == 404) {
                llSay(0, "That gate does not exist");
                resetStargate();
            } else if(status == 400) {
                llSay(0, "The network did not like that address");
                resetStargate();
            } else {
                llSay(0, "The network is experiencing issues.");
                resetStargate();   
            }
        }
    }
    
    touch_start(integer num) {
        if(currentState == 2) {
            Dialog(llDetectedKey(0), "ISN Stargate", ["Shut down"]);
        } else if(currentState < 3) {
            if(llDetectedKey(0) == llGetOwner()) {
                Dialog(llGetOwner(), "ISN Stargate", ["Reset", "Dial random", "Delete"]);   
            } else {
                Dialog(llDetectedKey(0), "ISN Stargate", ["Reset", "Dial random"]);
            }   
        }
    }

    http_request(key id, string method, string body) { 
        if(method == URL_REQUEST_GRANTED) {
            if(gateURL == "") { 
                registerNewGate(body); 
            } else if(gateURL != body) {
                registerNewGate(body);
            }
        } else if(method == URL_REQUEST_DENIED) {
            llOwnerSay("ERROR - Unable to aquire a URL, trying again in 1 second...");
            llSleep(1); 
            llRequestURL(); 
        } else if(method == "GET") {
            llHTTPResponse(id,200,"state: " + (string)currentState);
        } else if(method == "PUT") {
            list q = llParseString2List(body, ["|"], []);
            
            if(llList2String(q, 0) == "connection-request" & llGetListLength(q) == 3) {
                if(currentState < 2) {
                    connectedGateURL = llList2String(q, 1);
                    activateIncomingWormhole(llList2String(q, 2));
                    llHTTPResponse(id, 200, "go-ahead|"+ llGetRegionName() + "|" + (string)llGetPos());
                } else {
                    llHTTPResponse(id, 200, "busy");   
                }
            } else if(llList2String(q, 0) == "close-connection" && currentState == 3) {
                llHTTPResponse(id, 200, "closed");
                resetStargate();
            }
            
            llHTTPResponse(id, 200, "");
        } else if(method == "POST") {
            handleRemoteAPI(body);
        } else if(method == "DELETE") {
            if(currentState == 4) {
                llHTTPResponse(id, 200, "");
                llOwnerSay("Deleted from database.");
                llDie();
            } else {
                llHTTPResponse(id, 401, "");
            }
        } else {
            llHTTPResponse(id, 405, "Unsupported Method");
        }
    }
    
    listen(integer chan, string name, key id, string message) {
        if(chan == 0) {
            if(llStringLength(message) > 6 && llGetSubString(message, 0, 4) == "/dial") {
                string q = llGetSubString(message, 6, -1);
                            
                connectToNamedGate(q); 
            }
        } else if (chan == -12444) {
            handleLocalAPI(message, name, id);
        } else if(chan == evChannel & message == "event-horizon-ready" & currentState == 2) {
            llWhisper(chan, targetRegion + "|" + targetVectorString);
        } else if(chan == menuChannel) {
            if(currentState == 2 && message == "Shut down") {
                closeConnection();
            } else if(currentState < 3 && message == "Reset") {
                resetStargate();   
            } else if(currentState < 3 && message == "Dial random") {
                connectToNamedGate("random");
            } else if(currentState < 3 && id == llGetOwner() && message == "Delete") {
                setState(4);
                llOwnerSay("Deleting...");
                llHTTPRequest(
                    "http://" + networkHost + "/delete", 
                    [HTTP_METHOD, "DELETE"],
                    ""
                );
            }
        }
    }
    
    timer() {
        if(currentState == 2) {
            llHTTPRequest(
                connectedGateURL, 
                [HTTP_METHOD, "PUT"],
                "close-connection"
            ); 
        }
        resetStargate();
    }
}
