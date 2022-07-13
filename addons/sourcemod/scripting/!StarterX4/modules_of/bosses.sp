
#include "modules_of/base.sp"
#include "modules_of/forwards.sp"
#include "modules_of/gamemode.sp"
VSHGameMode gamemode;
/* VSHGameMode Singleton that controls the game state of the mod
Had to place it here because methodmaps can't be forward declared (yet) and neither can methodmap properties
*/

/* DO NOT DELETE/MODIFY ANYTHING BEFORE THIS LINE */

#include "modules_of/bosses/hale.sp"
#include "modules_of/bosses/vagineer.sp"
#include "modules_of/bosses/cbs.sp"
#include "modules_of/bosses/hhh.sp"
#include "modules_of/bosses/bunny.sp"