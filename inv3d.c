#include "lib.h"
#include "inv3d.h"
#include "pt3_lib.h"
#include "dflat_lib.h"

#define JOYSTICK 0

extern unsigned int xPos,yPos,xStep,yStep,friction;
extern unsigned int bulletX,bulletY,dx,dy;
extern unsigned char alienLevelSpeed, spriteMask, alien2Delay;
extern void drawSprite(unsigned char, unsigned char, unsigned char);
extern void loopLand();
extern void initLand();
extern void initBarLookUp();
extern void invertPaper(unsigned char);
extern void drawDeathStar(unsigned char, unsigned char, unsigned char);

extern unsigned char sprite_data[], udg_data[];
extern unsigned char oxygene4[], level_tune[];

unsigned int timer;

char systemName[9][20] = {
    "Alpha System",
    "Beta System",
    "Gamma System",
    "Delta System",
    "Epsilon System",
    "Zeta System",
    "Eta System",
    "Theta System",
    "Omega System"
};

unsigned char landColour[9][2] = {
    {16+6,16+2},
    {16+6,16+3},
    {16+6,16+5},
    {16+5,16+2},
    {16+5,16+3},
    {16+5,16+6},
    {16+3,16+2},
    {16+3,16+5},
    {16+3,16+6}
};

unsigned int sprTable[40];
unsigned int sprShip[5*12*3+10];
unsigned int sprAlien1[6*12*3+10], sprAlien2[6*11*3+10];
unsigned int sprAlien3[5*9*3+10], sprAlien4[5*8*3+10];
unsigned int sprAlien5[4*6*3+10], sprAlien6[4*4*3+10];
unsigned int sprAlien7[3*3*3+10], sprAlien8[3*2*3+10];
unsigned int sprBullet1[3*6*3+10], sprBullet2[3*5*3+10];
unsigned int sprBullet3[3*4*3+10], sprBullet4[3*3*3+10];
unsigned int sprBullet5[3*2*3+10], sprBullet6[3*1*3+10];
char d[50],t[50];

unsigned char soundfx=1;
unsigned int hiScore;
unsigned int score;
unsigned char state;
unsigned char startOffset;
unsigned char startColour;
unsigned char altColour;
unsigned char colour;
unsigned char colourFlip;
unsigned char barSize;
unsigned char aliensLeft;
unsigned char lives;
unsigned char level;
unsigned char *dataPtr;
unsigned char musicOn=1;
unsigned char ds_x,ds_y,ds_col;

void processSprite(unsigned char *spr) {
    unsigned char w,h,s;
    unsigned char x1,y1,x2,y2;
    int i,j,k,cin,cout;
    unsigned char *sprBase;

    sprBase=spr;                    // Initialize pointer

    // Width, height, size
    w=*dataPtr++; h=*dataPtr++; s=*dataPtr++;
    sprBase[0]=w; sprBase[1]=h; sprBase[2]=s;
    // Hitbox exents
    x1=*dataPtr++; y1=*dataPtr++;
    x2=*dataPtr++; y2=*dataPtr++;
    sprBase[3]=x1; sprBase[4]=y1;
    sprBase[5]=x2; sprBase[6]=y2;

    sprBase+=3+4+12;                // Data section
    for(j=0;j<h;j++) {
        sprBase[0]=*dataPtr++;      // Row colour
        for(k=1;k<=w;k++) {
            sprBase[k]=0;
            for(i=0;i<6;i++) {
                sprBase[k]<<=1;
                if(*dataPtr++ =='*')
                    sprBase[k] |= 1;
            }
            sprBase[k] |= 0x40;
        }
        sprBase+=1+w;               // Next row
    }

    spr+=7;                         // Move to table
    sprBase=spr+12;                 // Move to data       
    // Sprite pointer table for shifted patterns
    for(i=0; i<12; i+=2) {
        // Low byte
        spr[i]=(unsigned char)((unsigned int)sprBase & 0xff);
        // High byte
        spr[i+1]=(unsigned char)(((unsigned int)sprBase>>8) & 0xff);
        sprBase+=s;
    }

    // Create shifted versions
    sprBase=spr+12;                 // sprBase is the source
    spr=sprBase+s;                  // spr is the dest
    for(i=0; i<5; i++) {
        for(k=0; k<h; k++) {
            *spr++ = *sprBase++;        // Row colour
            cin=0;                      // Carry in
            for(j=0;j<w;j++) {
                // Remember carry out
                cout=(*sprBase&1)<<5;
                // Shift right bringing in carry in the leftmost bit
                *spr = (((*sprBase&0x3f)>>1)|cin)|0x40;
                // Next carry in is previous carry out
                cin=cout;
                spr++;
                sprBase++;
            }
        }
    }

}

void processUDGs() {
    unsigned char i,j,c;
    unsigned char *udgChar;

    while(c=*dataPtr++) {
        udgChar=(unsigned char*)(0xb400+c*8);
        for(i=0;i<8;i++)
            udgChar[i]=*dataPtr++;
    }
}


void generateSprites() {
    // Sprite index table
    sprTable[0]=(unsigned int)sprShip;
    sprTable[1]=(unsigned int)sprAlien8;
    sprTable[2]=(unsigned int)sprAlien7;
    sprTable[3]=(unsigned int)sprAlien6;
    sprTable[4]=(unsigned int)sprAlien5;
    sprTable[5]=(unsigned int)sprAlien4;
    sprTable[6]=(unsigned int)sprAlien4;
    sprTable[7]=(unsigned int)sprAlien3;
    sprTable[8]=(unsigned int)sprAlien3;
    sprTable[9]=(unsigned int)sprAlien2;
    sprTable[10]=(unsigned int)sprAlien2;
    sprTable[11]=(unsigned int)sprAlien2;
    sprTable[12]=(unsigned int)sprAlien1;
    sprTable[13]=(unsigned int)sprAlien1;
    sprTable[14]=(unsigned int)sprAlien1;
    sprTable[15]=(unsigned int)sprBullet6;
    sprTable[16]=(unsigned int)sprBullet6;
    sprTable[17]=(unsigned int)sprBullet5;
    sprTable[18]=(unsigned int)sprBullet5;
    sprTable[19]=(unsigned int)sprBullet5;
    sprTable[20]=(unsigned int)sprBullet4;
    sprTable[21]=(unsigned int)sprBullet4;
    sprTable[22]=(unsigned int)sprBullet4;
    sprTable[23]=(unsigned int)sprBullet3;
    sprTable[24]=(unsigned int)sprBullet3;
    sprTable[25]=(unsigned int)sprBullet2;
    sprTable[26]=(unsigned int)sprBullet2;
    sprTable[27]=(unsigned int)sprBullet1;
    sprTable[28]=(unsigned int)sprBullet1;

    dataPtr=sprite_data;
    processSprite((unsigned char*)sprShip);
    processSprite((unsigned char*)sprAlien1);
    processSprite((unsigned char*)sprAlien2);
    processSprite((unsigned char*)sprAlien3);
    processSprite((unsigned char*)sprAlien4);
    processSprite((unsigned char*)sprAlien5);
    processSprite((unsigned char*)sprAlien6);
    processSprite((unsigned char*)sprAlien7);
    processSprite((unsigned char*)sprAlien8);
    processSprite((unsigned char*)sprBullet1);
    processSprite((unsigned char*)sprBullet2);
    processSprite((unsigned char*)sprBullet3);
    processSprite((unsigned char*)sprBullet4);
    processSprite((unsigned char*)sprBullet5);
    processSprite((unsigned char*)sprBullet6);

    dataPtr=udg_data;
    processUDGs();

    spriteMask=0xff;
}

void dplot(char *t, char y, char dy, char a, char c1, char c2) {
    gr_tplot(0,y,(char*)a);
    gr_tplot(0,y+dy,(char*)a);
    gr_tplot(1,y,(char*)c1);
    gr_tplot(1,y+dy,(char*)c2);
    gr_tplot(20-strlen(t)/2,y,t);
    gr_tplot(20-strlen(t)/2,y+dy,t);
}

void wait(int ticks) {
    unsigned int startTime;

    gr_resetTimer(&startTime);
    while(gr_elapsed(startTime)<ticks) {
    }   
}

void textScreenColour(char b, char f) {
    int i;

    b+=16;
    for(i=0; i<3; i++) {
        gr_tplot(0,i,(char *)b);
        gr_tplot(1,i,(char *)f);
    }
}


void doInstructions() {
    text();
    poke(0x26A, 10);
    paper(0);
    ink(7);
    cls();
//    pt3_mod(oxygene4,0);
    gr_tplot(35,0,"     "); // Clear the CAPS logo
    dplot("GALAXY DEFENDER 3026",0,1,10,1,3);
    dplot("You are the last defender of our    ",4,0,8,7,7);
    dplot("Milky Way galaxy, all our comrades  ",5,0,8,7,7);
    dplot("have fallen to the evil Andromeda   ",6,0,8,7,7);
    dplot("empire.                             ",7,0,8,7,7);
    dplot("Incoming intelligence..",9,0,12,1,1);
    wait(200);
    dplot("Latest intelligence indicates that  ",9,0,8,7,7);
    dplot("the Andromeda hordes are now at the ",10,0,8,7,7);
    dplot("outer systems of our galaxy in full ",11,0,8,7,7);
    dplot("annhilation mode. Billions of souls ",12,0,8,7,7);
    dplot("are at risk and you must stop them. ",13,0,8,7,7);
    dplot("Preparing your ship..",15,0,12,1,1);
    wait(200);
    dplot("Your ship is the latest Sabre class ",15,0,8,7,7);
    dplot("and equipped with pulse torpedoes.  ",16,0,8,7,7);
    dplot("To halt the enemy advance, you must ",17,0,8,7,7);
    dplot("destroy at least 10 of their ships. ",18,0,8,7,7);
    dplot("This will cause them to change their",19,0,8,7,7);
    dplot("attack vector to another system and ",20,0,8,7,7);
    dplot("you must follow them relentlessly.  ",21,0,8,7,7);
    dplot("Control your ship using left+right &",22,0,8,7,7);
    dplot("fire torpedoes with space.          ",23,0,8,7,7);
    dplot("Loading weapons..",26,1,14,4,6);
    wait(200);
    dplot("  PRESS ANY KEY!  ",26,1,14,7,3);
    gr_resetTimer(&timer);
    do; while(!kb_stick());
//    pt3_mute();
    srandom(timer);
    state=stateAttract;
}


void drawScreen(char l, char s) {
    int col;
    int i,j,k;
    unsigned int t;
    unsigned char *scrnPtr;

    if(s) pt3_mod(level_tune,0);

    // Rolling landscape
    startOffset=0;
    colourFlip=0;
    initLand();

    // Sky
    col=16+((l+1)%4)+3;
    scrnPtr=(unsigned char*)0xa000;
    for(j=0; j<horizon; j+=2) {
        *scrnPtr=col;
        scrnPtr+=80;
    }

    // Stars
    for(j=0; j<50; j++)
        curset(rand()%228+6,rand()%(horizon-5),1);

    // Moon ink colour
    ds_col=l%7+1;
    // Top position of moon
    ds_y=rand()%(horizon-50)+5;
    // X position of moon
    ds_x=rand()%20+2;

    // Scroll the death star up from horizon
    for(i=horizon-1;i>=ds_y;i--) {
        gr_resetTimer(&t);
        drawDeathStar(ds_col,ds_x,i);
        initLand();
        while(gr_elapsed(t)<3);
    }

    if(s) pt3_mute();
}


void drawPanel() {
    int i;
    char text[20];

    cls();
    textScreenColour(0,4);
    gr_tplot(1,0,(char*)4);
    gr_tplot(2,0,"SCORE");
    sprintf(text,"%x",score);
    text[4]='\0';
    gr_tplot(7,0,(char*)2);
    gr_tplot(8,0,text);
    gr_tplot(12,0,(char*)4);
    gr_tplot(14,0,"LIVES");
    gr_tplot(19,0,(char*)5);
    for(i=0;i<lives;i++)
        gr_tplot(20+i,0,(char*)'{');
    gr_tplot(27,0,(char*)4);
    gr_tplot(28,0,"HISCORE");
    sprintf(text,"%x",hiScore);
    text[4]='\0';
    gr_tplot(36,0,text);
    gr_tplot(35,0,(char*)2);
    gr_tplot(5,1,(char*)4);
    gr_tplot(6,1,"ENEMIES REMAINING");
    gr_tplot(23,1,(char*)1);
    for(i=0;i<aliensLeft;i++)
        gr_tplot(24+i,1,(char*)'}');
}

void show_jkm_txt() {
#if JOYSTICK
    if(!kb_stat)
        gr_hplot(108,185,"^^^^^^^^           ");
    else
        gr_hplot(108,185,"           ^^^^^^^^");
#endif
        if(musicOn)
        gr_hplot(144,165,"ON ");
    else
        gr_hplot(144,165,"OFF");
}

void attract() {
    unsigned char k;
    unsigned int timer;
/*
    printf("Joy=%x\n\r",kb_stat); wait(200);
    do {
        k=kb_stick();
        printf("%x\n\r",k);
        wait(50);
    } while(1||!(k&16));
*/
    hires(); poke(0x26A, 10);
    startOffset=0;
    startColour=16+3;
    altColour=16+5;
    colourFlip=0;
    pt3_mod(oxygene4,0);
    if(!musicOn)
        pt3_mute();
    textScreenColour(0,4);
    gr_tplot(0,1,(char *)14); gr_tplot(0,2,(char *)14);
    gr_tplot(1,1,(char *)1); gr_tplot(1,2,(char *)3);
    gr_tplot(6,1,"} } GALAXY DEFENDER 3026 } }");
    gr_tplot(6,2,"} } GALAXY DEFENDER 3026 } }");
    drawScreen(0,0);
    gr_hplot(18,145,(char *)0);
    gr_hplot(18,155,(char *)0);
    gr_hplot(18,165,(char *)0);
    gr_hplot(18,175,(char *)0);
    gr_hplot(18,185,(char *)0);
    gr_hplot(24,145,"SPACE/Fire : Begin defence!");
    gr_hplot(24,155,"UP         : Instructions");
    gr_hplot(24,165,"M          : Music");
#if JOYSTICK
    gr_hplot(24,175,"K/J        : [KEYBOARD] [JOYSTICK]");
#endif
    show_jkm_txt(kb_stat);
    gr_resetTimer(&timer);
    do {
        k=peek(0x2df)&0x7f; // Read keyboard
        if((k=='J')||(k=='K')||(k=='M')) {    // Pressed J, K or M
            gr_pixmode(0);
            show_jkm_txt();
            gr_pixmode(1);
#if JOYSTICK
            if(k=='K')
               kb_stat=0;
            if(k=='J')
                kb_stat = 0x20;
#endif
                if(k=='M') {
                musicOn ^= 1;
                if(musicOn)
                    pt3_unmute();
                else
                    pt3_mute();
            }
            show_jkm_txt(kb_stat);
        }
        poke(0x2df,0); // Clear keyboard char

        k=kb_stick();
        if(gr_elapsed(timer)>4) {
            gr_resetTimer(&timer);
            initLand();
        }
    } while((k!=4)&&(k!=16));
//    printf("%x\n\r",k); wait(500);
    if (k==4)
        state=stateInstruct;
    else {
        state=stateInitGame;
        pt3_mute();
    }
}

void initGame() {
    level=0;
    xPos=128<<8; 
    yPos=185<<8;
    lives=5;
    score=0;
    state=statePlayGame;
}

void loseLife() {
    unsigned char i;
 
    gr_tplot(20+lives,0,(char*)' ');
    gr_tplot(2,2,"  \01} }\07AN INVADER GOT THROUGH!\01} }   ");
    spriteMask=0xff;
    drawSprite(0,xPos>>8,yPos>>8);
    explode();
    for(i=0; i<=40; i++) {
        gr_tplot(1,2,(char*)((i%5)+3));
        invertPaper(0x07);
        wait(3);
    }
    invertPaper(0x07);
}

void gameOver() {
    gr_tplot(2,2, " Bad luck pilot, the hordes got you!!");
    wait(200);
    if(score>hiScore) {
        gr_tplot(2,2,"\07\14** But you got the high score **    ");
        hiScore=score;
        sprintf(t,"%x",hiScore);
        t[4]='\0';
        gr_tplot(36,0,t);
        gr_tplot(27,0,(char*)12);
        zap(); zap(); zap();
        wait(100);
    }
    wait(200);
    state=stateAttract;
}

void playGame() {
    int z;
    char t[20];

    startOffset=0;
    startColour=landColour[level][0];
    altColour=landColour[level][1];
    colourFlip=0;

    xStep=96; yStep=96; friction=48;
    bulletY=0;
    alienLevelSpeed=10-level;
    aliensLeft=10;
    hires(); poke(0x26A, 10);
    textScreenColour(0,4);
    drawPanel();
    drawScreen(level,1);
    z=strlen(systemName[level]);
    gr_hplot(120-3*z,0,systemName[level]);

    do {
        play(4+2+1,4+1,0,0);
        sound(1,0,0); sound(2,0,0); sound(3,500,0); sound(0,30,0);
        state=statePlayGame;
        dx=0; dy=0;
        spriteMask=0xff;
        drawSprite(0,xPos>>8, yPos>>8);
        alien2Delay=8;
//        pt3_mod(oxygene4,0);
        loopLand(0,0,0);
//        pt3_mute();
        if(state==stateLoseLife)
            loseLife();
    } while((state!=stateNextLevel)&&(lives!=0));
    play(0,0,0,0);
    
    if(lives==0) gameOver();
}

void nextLevel() {
    unsigned int i,t;

    sound(1,400,0); sound(2,401,0); sound(3,402,0);
    play(7,0,0,6000);
    cls();
    textScreenColour(5,3);
    gr_tplot(2,0," Well done you, thwarted the hordes! ");
    wait(100);
    if(level<7) {
        gr_tplot(2,1,"But the next system is under attack! ");
        level++;
    } else {
        gr_tplot(2,1,"      BUT THEY HAVE RE-GROUPED!      ");
    }
    gr_tplot(1,2,(char*)0);
    gr_tplot(2,2,"** The galaxy is depending on you ** ");
    // Scroll the death down into horizon
    for(i=ds_y;i<horizon;i++) {
        gr_resetTimer(&t);
        drawDeathStar(ds_col,ds_x,i);
        initLand();
        while(gr_elapsed(t)<3);
    }
    wait(100);
    state=statePlayGame;
}


void game_boot() {
    int i;

    generateSprites();
    initBarLookUp();
}

void main() {
    int i;
    unsigned char x,y;
    char dx;

    poke(0x26A, 10);        // No cursor or key clicks
    gr_init();
    kb_stat=0;              // Default to keyboard mode
    pt3_init();
    game_boot();

    while(1) {
        switch(state) {
            case stateInstruct: doInstructions(); break;
            case stateAttract: attract(); break;
            case stateInitGame: initGame(); break;
            case statePlayGame: playGame(); break;
            case stateNextLevel: nextLevel(); break;
            case stateLoseLife: loseLife(); break;
        }

    }
}
