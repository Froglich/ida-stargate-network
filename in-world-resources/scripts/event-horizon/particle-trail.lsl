updateParticles(float accel) {
    llParticleSystem([
        PSYS_PART_FLAGS,(0 | PSYS_PART_FOLLOW_SRC_MASK | PSYS_PART_EMISSIVE_MASK),
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP ,
        PSYS_PART_START_ALPHA,1,
        PSYS_PART_END_ALPHA,1,
        PSYS_PART_START_COLOR,<1,1,1> ,
        PSYS_PART_END_COLOR,<1,1,1> ,
        PSYS_PART_START_GLOW,0,
        PSYS_PART_END_GLOW,0,
        PSYS_PART_START_SCALE,<3,3,3>,
        PSYS_PART_END_SCALE,<3.5,3.5,3.5>,
        PSYS_PART_MAX_AGE,2,
        PSYS_SRC_MAX_AGE,0,
        PSYS_SRC_ACCEL,<0,0,accel>*llGetRot(),
        PSYS_SRC_BURST_PART_COUNT,5,
        PSYS_SRC_BURST_RADIUS,0,
        PSYS_SRC_BURST_RATE,0.1,
        PSYS_SRC_BURST_SPEED_MIN,2,
        PSYS_SRC_BURST_SPEED_MAX,0.5,
        PSYS_SRC_ANGLE_BEGIN,0,
        PSYS_SRC_ANGLE_END,0,
        PSYS_SRC_OMEGA,<0,0,0>,
        //PSYS_SRC_TEXTURE, "",
        PSYS_SRC_TARGET_KEY, llGetKey()
     ]);   
}

float acceleration = 3;

default {    
    link_message(integer sender_num, integer num, string str, key id) {
        if(str == "particles") {
            acceleration = 3;
            updateParticles(3);
            llSetTimerEvent(0.1);
        }
    }
    
    timer() {
        if(acceleration == 0) {
            llParticleSystem([]);
            llSetTimerEvent(0);
            return;
        }
        
        acceleration -= 0.25;   
        updateParticles(acceleration);
    }
}