# 修改XKore模式的端口保证一机多开内挂
# 插件修订: Maple
# 发布 CN Kore Team
# Revision: r213
# Date: 2013年4月24日 01:43:09
package changePort; 
  
use strict; 
use Plugins; 
use Settings; 
use Globals; 
use Utils; 
use Misc; 
use Config; 
  
Plugins::register("changePort", "Change the Port in NetRedirect.dll for XKore", \&unload); 
my $hooks = Plugins::addHooks( 
    ['start3', \&changePort], 
); 
  
sub unload { 
    Plugins::delHooks($hooks); 
} 
sub changePort { 
    return if $config{XKore} ne "1"; 
    my $DLLfile = $config{XKore_dll} || "NetRedirect.dll"; 
    unless (-e $DLLfile) { 
        `COPY NetRedirect.dll $DLLfile`; 
    } 
    open(FILE, "+<$DLLfile"); 
    seek(FILE, 5226, 0); 
    print FILE pack('S',$config{XKore_port} || 2350); 
    close(FILE); 
} 
  
  
1;