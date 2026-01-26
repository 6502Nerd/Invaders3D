#ifndef INV3D_H
#define INV3D_H

#define stateAttract    0
#define stateInitGame   1
#define statePlayGame   2
#define stateNextLevel  3
#define stateLoseLife   4
#define stateInstruct   5

#define hiresText       0xbf68
#define scoreAddress    (0xbf68+40*0+8)
#define livesAddress    0xbf68+40*0+20
#define enemiesBar      (0xbf68+40*1+24)
#define base            (0xa000+199*40)
#define horizon         80
#define perspective     4
#define leftMargin      10
#define rightMargin     210

#endif
