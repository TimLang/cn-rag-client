#######################################
#######################################
#FILE PARSING AND WRITING
#######################################
#######################################

sub addParseFiles {
        my $file = shift;
        my $hash = shift;
        my $function = shift;
        $parseFiles[$parseFiles]{'file'} = $file;
        $parseFiles[$parseFiles]{'hash'} = $hash;
        $parseFiles[$parseFiles]{'function'} = $function;
        $parseFiles++;
}

# ICE Start - Chat Log
sub chatLog {
        my $type = shift;
        my $message = shift;
	if ($type eq "c") {
		$file = "chat_public.txt";
	} elsif ($type eq "pm") {
		$file = "chat_private.txt";
	} elsif ($type eq "p") {
		$file = "chat_party.txt";
	} elsif ($type eq "g") {
		$file = "chat_guild.txt";
	} elsif ($type eq "s") {
		$file = "chat_notice.txt";

	} elsif ($type eq "b") {
		$file = "item_buysell.txt";
	} elsif ($type eq "i") {
		$file = "item_pickup.txt";

	} elsif ($type eq "gm") {
		$file = "event_gm.txt";
	} elsif ($type eq "x") {
		$file = "event_system.txt";
	} elsif ($type eq "m") {
		$file = "event_monster.txt";
	} elsif ($type eq "d") {
		$file = "event_dead.txt";
	} else {
		$file = "event_other.txt";
	}
	open FILE, ">> $logs_path/$file";
        print FILE "[".getFormattedDate(int(time))."] $message";
        close FILE;
}
# ICE End

sub chatLog_clear {
        if (-e "$logs_path/chat_public.txt") { unlink("$logs_path/chat_public.txt"); }
        if (-e "$logs_path/chat_private.txt") { unlink("$logs_path/chat_private.txt"); }
        if (-e "$logs_path/chat_party.txt") { unlink("$logs_path/chat_party.txt"); }
        if (-e "$logs_path/chat_guild.txt")   { unlink("$logs_path/chat_guild.txt"); }
        if (-e "$logs_path/chat_notice.txt")   { unlink("$logs_path/chat_notice.txt"); }
        if (-e "$logs_path/item_inventory.txt")   { unlink("$logs_path/item_inventory.txt"); }
        if (-e "$logs_path/item_storage.txt")   { unlink("$logs_path/item_storage.txt"); }
        if (-e "$logs_path/item_cart.txt")   { unlink("$logs_path/item_cart.txt"); }
        if (-e "$logs_path/item_buysell.txt")   { unlink("$logs_path/item_buysell.txt"); }
        if (-e "$logs_path/item_pickup.txt")   { unlink("$logs_path/item_pickup.txt"); }
        if (-e "$logs_path/event_gm.txt")   { unlink("$logs_path/event_gm.txt"); }
        if (-e "$logs_path/event_system.txt")   { unlink("$logs_path/event_system.txt"); }
        if (-e "$logs_path/event_monster.txt")   { unlink("$logs_path/event_monster.txt"); }
        if (-e "$logs_path/event_dead.txt")   { unlink("$logs_path/event_dead.txt"); }
        if (-e "$logs_path/event_other.txt")   { unlink("$logs_path/event_other.txt"); }
        if (-e "$logs_path/exp.txt")   { unlink("$logs_path/exp.txt"); }
}


#sub convertGatField {
#        my $file = shift;
#        my $r_hash = shift;
#        my $i;
#        open FILE, "+> $file";
#        binmode(FILE);
#        print FILE pack("S*", $$r_hash{'width'}, $$r_hash{'height'});
#        for ($i = 0; $i < @{$$r_hash{'field'}}; $i++) {
#                print FILE pack("C1", $$r_hash{'field'}[$i]);
#        }
#        close FILE;
#}

sub dumpData {
        my $msg = shift;
        my $dump;
        my $i;
        $dump = "\n\n================================================\n".getFormattedDate(int(time))."\n\n".length($msg)." bytes\n\n";
        for ($i=0; $i + 15 < length($msg);$i += 16) {
                $dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,8))."\n";
        }
        if (length($msg) - $i > 8) {
                $dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,length($msg) - $i - 8))."\n";
        } elsif (length($msg) > 0) {
                $dump .= getHex(substr($msg,$i,length($msg) - $i))."\n";
        }
        open DUMP, ">> DUMP.txt";
        print DUMP $dump;
        close DUMP;
        print "$dump\n" if $config{'debug'} >= 2;
        print "Message Dumped into DUMP.txt!\n";
}

sub getField {
        my $file = shift;
        my $r_hash = shift;
        my $i, $data;
        undef %{$r_hash};
        if (!(-e $file)) {
                print "\n!!Could not load field - you must install the kore-field pack!!\n\n";
        }
        if ($file =~ /\//) {
                ($$r_hash{'name'}) = $file =~ /\/([\s\S]*)\./;
        } else {
                ($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
        }
        open FILE, $file;
        binmode(FILE);
        read(FILE, $data, 4);
        my $width = unpack("S1", substr($data, 0,2));
        my $height = unpack("S1", substr($data, 2,2));
        $$r_hash{'width'} = $width;
        $$r_hash{'height'} = $height;
        while (read(FILE, $data, 1)) {
                #$$r_hash{'field'}[$i] = unpack("C",$data);
                $$r_hash{'rawMap'} .= $data;
                #$i++;
        }
        close FILE;
}

#sub getGatField {
#        my $file = shift;
#        my $r_hash = shift;
#        my $i, $data;
#        undef %{$r_hash};
#        ($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
#        open FILE, $file;
#        binmode(FILE);
#        read(FILE, $data, 16);
#        my $width = unpack("L1", substr($data, 6,4));
#        my $height = unpack("L1", substr($data, 10,4));
#        $$r_hash{'width'} = $width;
#        $$r_hash{'height'} = $height;
#        while (read(FILE, $data, 20)) {
#                $$r_hash{'field'}[$i] = unpack("C1", substr($data, 14,1));
#                $i++;
#        }
#        close FILE;
#}

sub getResponse {
        my $type = shift;
        my $key;
        my @keys;
        my $msg;
        foreach $key (keys %responses) {
                if ($key =~ /^$type\_\d+$/) {
                        push @keys, $key;
                }
        }
        $msg = $responses{$keys[int(rand(@keys))]};
        $msg =~ s/\%\$(\w+)/$responseVars{$1}/eig;
        return $msg;
}

sub load {
        my $r_array = shift;
        my $printType = shift;

        foreach (@{$r_array}) {
                if (-e $$_{'file'}) {
                        printc("yn", "<系统> ", "正在加载 $$_{'file'}...\n");
                } else {
                        printc("yr", "<系统> ", "无法加载 $$_{'file'}\n");
                }
                &{$$_{'function'}}("$$_{'file'}", $$_{'hash'});
        }
        startKoreEasy();
}



sub parseDataFile {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,$value;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+$//g;
                ($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
                if ($key ne "" && $value ne "") {
                        $$r_hash{$key} = $value;
                }
        }
        close FILE;
}

sub parseDataFile_lc {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,$value;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+$//g;
                ($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
                if ($key ne "" && $value ne "") {
                        $$r_hash{lc($key)} = $value;
                }
        }
        close FILE;
}

sub parseDataFile2 {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,$value;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+$//g;
                ($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
                $key =~ s/\s//g;
                if ($key eq "") {
                        ($key) = $_ =~ /([\s\S]*)$/;
                        $key =~ s/\s//g;
                }
                if ($key ne "") {
                        $$r_hash{$key} = $value;
                }
        }
        close FILE;
}

sub parseItemsControl {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,@args;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+$//g;
                ($key, $args) = $_ =~ /([\s\S]+?) (\d+[\s\S]*)/;
                @args = split / /,$args;
                if ($key ne "") {
                        $$r_hash{lc($key)}{'keep'} = $args[0];
                        $$r_hash{lc($key)}{'storage'} = $args[1];
                        $$r_hash{lc($key)}{'sell'} = $args[2];
                }
        }
        close FILE;
}

sub parseNPCs {
        my $file = shift;
        my $r_hash = shift;
        my $i, $string;
        undef %{$r_hash};
        my $key,$value;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+/ /g;
                s/\s+$//g;
                @args = split /\s/, $_;
                if (@args > 4) {
                        $$r_hash{$args[0]}{'map'} = $args[1];
                        $$r_hash{$args[0]}{'pos'}{'x'} = $args[2];
                        $$r_hash{$args[0]}{'pos'}{'y'} = $args[3];
                        $string = $args[4];
                        for ($i = 5; $i < @args; $i++) {
                                $string .= " $args[$i]";
                        }
                        $$r_hash{$args[0]}{'name'} = $string;
                }
        }
        close FILE;
}

sub parseMonControl {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,@args;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+$//g;
                ($key, $args) = $_ =~ /([\s\S]+?) (\d+[\s\S]*)/;
                @args = split / /,$args;
                if ($key ne "") {
                        $$r_hash{lc($key)}{'attack_auto'} = $args[0];
                        $$r_hash{lc($key)}{'teleport_auto'} = $args[1];
                        $$r_hash{lc($key)}{'teleport_count'} = $args[2];
                }
        }
        close FILE;
}

sub parsePortals {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,$value;
        my %IDs;
        my $i;
        my $j = 0;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+/ /g;
                s/\s+$//g;
                @args = split /\s/, $_;
                if (@args > 5) {
                        $IDs{$args[0]}{$args[1]}{$args[2]} = "$args[0] $args[1] $args[2]";
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'ID'} = "$args[0] $args[1] $args[2]";
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'map'} = $args[0];
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'pos'}{'x'} = $args[1];
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'pos'}{'y'} = $args[2];
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'map'} = $args[3];
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'pos'}{'x'} = $args[4];
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'pos'}{'y'} = $args[5];
                        if ($args[6] ne "") {
                                $$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'ID'} = $args[6];
                                for ($i = 7; $i < @args; $i++) {
                                        $$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'steps'}[@{$$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'steps'}}] = $args[$i];
                                }
                        }
                }
                $j++;
        }
        foreach (keys %{$r_hash}) {
                $$r_hash{$_}{'dest'}{'ID'} = $IDs{$$r_hash{$_}{'dest'}{'map'}}{$$r_hash{$_}{'dest'}{'pos'}{'x'}}{$$r_hash{$_}{'dest'}{'pos'}{'y'}};
        }
        close FILE;
}

sub parsePortalsLOS {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+/ /g;
                s/\s+$//g;
                @args = split /\s/, $_;
                if (@args) {
                        $map = shift @args;
                        $x = shift @args;
                        $y = shift @args;
                        for ($i = 0; $i < @args; $i += 4) {
                                $$r_hash{"$map $x $y"}{"$args[$i] $args[$i+1] $args[$i+2]"} = $args[$i+3];
                        }
                }
        }
        close FILE;
}

sub parseReload {
        my $temp = shift;
        my @temp;
        my %temp;
        my $temp2;
        my $except;
        my $found;
        while ($temp =~ /(\w+)/g) {
                $temp2 = $1;
                $qm = quotemeta $temp2;
                if ($temp2 eq "all") {
                        foreach (@parseFiles) {
                                $temp{$$_{'file'}} = $_;
                        }
                } elsif ($temp2 =~ /\bexcept\b/i || $temp2 =~ /\bbut\b/i) {
                        $except = 1;
                } else {
                        if ($except) {
                                foreach (@parseFiles) {
                                        delete $temp{$$_{'file'}} if $$_{'file'} =~ /$qm/i;
                                }
                        } else {
                                foreach (@parseFiles) {
                                        $temp{$$_{'file'}} = $_ if $$_{'file'} =~ /$qm/i;
                                }
                        }
                }
        }
        foreach $temp (keys %temp) {
                $temp[@temp] = $temp{$temp};
        }
        load(\@temp);
}

sub parseResponses {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,$value;
        my $i;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                ($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
                if ($key ne "" && $value ne "") {
                        $i = 0;
                        while ($$r_hash{"$key\_$i"} ne "") {
                                $i++;
                        }
                        $$r_hash{"$key\_$i"} = $value;
                }
        }
        close FILE;
}

sub parseROLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        open FILE, $file;
        foreach (<FILE>) {
                s/\r//g;
                next if /^\/\//;
                @stuff = split /#/, $_;
                $stuff[1] =~ s/_/ /g;
                if ($stuff[0] ne "" && $stuff[1] ne "") {
                        $$r_hash{$stuff[0]} = $stuff[1];
                }
        }
        close FILE;
}

sub parseRODescLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $ID;
        my $IDdesc;
        open FILE, $file;
        foreach (<FILE>) {
                s/\r//g;
                if (/^#/) {
                        $$r_hash{$ID} = $IDdesc;
                        undef $ID;
                        undef $IDdesc;
                } elsif (!$ID) {
                        ($ID) = /([\s\S]+)#/;
                } else {
                        $IDdesc .= $_;
                        $IDdesc =~ s/\^......//g;
                        $IDdesc =~ s/_/--------------/g;
                }
        }
        close FILE;
}

sub parseROSlotsLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $ID;
        open FILE, $file;
        foreach (<FILE>) {
                if (!$ID) {
                        ($ID) = /(\d+)#/;
                } else {
                        ($$r_hash{$ID}) = /(\d+)#/;
                        undef $ID;
                }
        }
        close FILE;
}

sub parseSkillsLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        my $i;
        open FILE, $file;
        $i = 1;
        foreach (<FILE>) {
                @stuff = split /#/, $_;
                $stuff[1] =~ s/_/ /g;
                if ($stuff[0] ne "" && $stuff[1] ne "") {
                        $$r_hash{$stuff[0]} = $stuff[1];
                }
                $i++;
        }
        close FILE;
}


sub parseSkillsIDLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        my $i;
        open FILE, $file;
        $i = 1;
        foreach (<FILE>) {
                @stuff = split /#/, $_;
                $stuff[1] =~ s/_/ /g;
                if ($stuff[0] ne "" && $stuff[1] ne "") {
                        $$r_hash{$i} = $stuff[1];
                }
                $i++;
        }
        close FILE;
}

sub parseSkillsReverseLUT_lc {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        my $i;
        open FILE, $file;
        $i = 1;
        foreach (<FILE>) {
                @stuff = split /#/, $_;
                $stuff[1] =~ s/_/ /g;
                if ($stuff[0] ne "" && $stuff[1] ne "") {
                        $$r_hash{lc($stuff[1])} = $stuff[0];
                }
                $i++;
        }
        close FILE;
}

sub parseSkillsSPLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $ID;
        my $i;
        $i = 1;
        open FILE, $file;
        foreach (<FILE>) {
                if (/^\@/) {
                        undef $ID;
                        $i = 1;
                } elsif (!$ID) {
                        ($ID) = /([\s\S]+)#/;
                } else {
                        ($$r_hash{$ID}{$i++}) = /(\d+)#/;
                }
        }
        close FILE;
}

sub parseTimeouts {
        my $file = shift;
        my $r_hash = shift;
        my $key,$value;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                ($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
                if ($key ne "" && $value ne "") {
                        $$r_hash{$key}{'timeout'} = $value;
                }
        }
        close FILE;
}

sub writeDataFile {
        my $file = shift;
        my $r_hash = shift;
        my $key,$value;
        open FILE, "+> $file";
        foreach (keys %{$r_hash}) {
                if ($_ ne "") {
                        print FILE "$_ $$r_hash{$_}\n";
                }
        }
        close FILE;
}

sub writeDataFileIntact {
        my $file = shift;
        my $r_hash = shift;
        my $data;
        my $key;
        open FILE, $file;
        foreach (<FILE>) {
                if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
                        $data .= $_;
                        next;
                }
                ($key) = $_ =~ /^(\w+)/;
                $data .= "$key $$r_hash{$key}\n";
        }
        close FILE;
        open FILE, "+> $file";
        print FILE $data;
        close FILE;
}

sub writeDataFileIntact2 {
        my $file = shift;
        my $r_hash = shift;
        my $data;
        my $key;
        open FILE, $file;
        foreach (<FILE>) {
                if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
                        $data .= $_;
                        next;
                }
                ($key) = $_ =~ /^(\w+)/;
                $data .= "$key $$r_hash{$key}{'timeout'}\n";
        }
        close FILE;
        open FILE, "+> $file";
        print FILE $data;
        close FILE;
}

sub writePortalsLOS {
        my $file = shift;
        my $r_hash = shift;
        open FILE, "+> $file";
        foreach $key (keys %{$r_hash}) {
                next if (!(keys %{$$r_hash{$key}}));
                print FILE $key;
                foreach (keys %{$$r_hash{$key}}) {
                        print FILE " $_ $$r_hash{$key}{$_}";
                }
                print FILE "\n";
        }
        close FILE;
}

sub updateMonsterLUT {
        my $file = shift;
        my $ID = shift;
        my $name = shift;
        open FILE, ">> $file";
        print FILE "$ID $name\n";
        close FILE;
}

sub updatePortalLUT {
        my ($file, $src, $x1, $y1, $dest, $x2, $y2) = @_;
        open FILE, ">> $file";
        print FILE "$src $x1 $y1 $dest $x2 $y2\n";
        close FILE;
}

sub updateNPCLUT {
        my ($file, $ID, $map, $x, $y, $name) = @_;
        open FILE, ">> $file";
        print FILE "$ID $map $x $y $name\n";
        close FILE;
}

1;