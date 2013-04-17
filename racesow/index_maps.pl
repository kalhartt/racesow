#!/usr/bin/perl

use strict;
use warnings;

use autodie;
use Getopt::Long;
use File::Find;

use Archive::Zip;

my $dir = $ENV{'HOME'} . '/.warsow-1.0/basewsw/';
my $delete_unused = 0;

GetOptions(
    "delete-unused" => \$delete_unused
) or exit 1;

if (@ARGV) {
    $dir = $ARGV[0];
}

my $files;

clean();
analyze();
exit;

sub subdirs {
    my($base) = @_;
    my @dirs;
    my $dir;
    opendir $dir, $base;
    while (my $file = readdir $dir) {
        if (-d "$base/$file" && $file ne '.' && $file ne '..') {
            push @dirs, $file;
        }
    }
    closedir $dir;
    return @dirs;
}

sub clean {
    $files = {
        '' => []
    };
}

sub exists_after {
    my($base, $file) = @_;
    for my $base2(keys %{$files}) {
        my @filtered;
        for my $file2(@{$files->{$base2}}) {
            if ($file eq $file2) {
                return $base ne '' && ($base2 gt $base || $base2 eq '');
            }
        }
    }
    return 0;
}

sub analyze {
    find(\&encounter_file, $dir);
    my @maps = ();
    for my $pk3(keys %{$files}) {
        for my $file(@{$files->{$pk3}}) {
            if ($file =~ /([^\/\.]*)\.bsp$/ && !contains($1, @maps)) {
                my $name = $1;
                push @maps, $name;
                my $longname = '';
                my $status = 'enabled';
                my @weapons = ('0', '0', '0', '0', '0', '0', '0');
                my $content = read_file($dir . $pk3, $file);
                $content =~ /("classname".*)\x00/s;
                $content = $1;
                if ($content =~ /[^{]*"message"\s*"(.*?)"/s) {
                    $longname = $1;
                }
                if ($content !~ /"classname"\s*"target_startTimer"/i) {
                    $status = 'disabled';
                } elsif ($content !~ /"classname"\s*"target_stopTimer"/i) {
                    $status = 'disabled';
                }
                if ($content =~ /"classname"\s*"weapon_machinegun"/i) {
                    $weapons[0] = '1';
                }
                if ($content =~ /"classname"\s*"weapon_riotgun"/i) {
                    $weapons[1] = '1';
                }
                if ($content =~ /"classname"\s*"weapon_grenadelauncher"/i) {
                    $weapons[2] = '1';
                }
                if ($content =~ /"classname"\s*"weapon_rocketlauncher"/i) {
                    $weapons[3] = '1';
                }
                if ($content =~ /"classname"\s*"weapon_plasmagun"/i) {
                    $weapons[4] = '1';
                }
                if ($content =~ /"classname"\s*"weapon_lasergun"/i) {
                    $weapons[5] = '1';
                }
                if ($content =~ /"classname"\s*"weapon_electrobolt"/i) {
                    $weapons[6] = '1';
                }
                print "INSERT INTO `map` (`name`, `status`, `longname`, `weapons`, `created`) SELECT '$name', '$status', '$longname', '" . (join '', @weapons) . "', NOW() FROM `map` WHERE `name`<>'$name' LIMIT 1;\n";
            }
        }
    }
    if ($delete_unused && @maps) {
        print 'DELETE FROM `map` WHERE `name` NOT IN (' . (join ', ', map {"'$_'"} @maps) . ");\n";
    }
}

sub remove_duplicates {
    for my $base(keys %{$files}) {
        my @filtered;
        for my $file(@{$files->{$base}}) {
            if (!exists_after($base, $file)) {
                push @filtered, $file;
            }
        }
        $files->{$base} = \@filtered;
    }
}

sub is_pak {
    my($file) = @_;
    return $file =~ /\.(pk3|pak|pk2)$/;
}

sub encounter_file {
    my $file = $File::Find::name;
    $file =~ s/^$dir//;
    if ($file . '/' ne $dir && !-d $File::Find::name) {
        if (is_pak($file)) {
            analyze_pk3($file);
        } else {
            push @{$files->{''}}, $file;
        }
    }
}

sub analyze_pk3 {
    my($pk3) = @_;
    my $zip = Archive::Zip->new();
    if (!$zip->read($dir . $pk3)) {
        $files->{$pk3} = [files($zip->memberNames())];
    }
}

sub files {
    my(@total) = @_;
    return grep !/\/$/, @total;
}

sub read_file {
    my($base, $file) = @_;
    my $result;
    if (is_pak($base)) {
        my $zip = Archive::Zip->new();
        $zip->read($base);
        $result = $zip->contents($file);
    } else {
        my $fh;
        local $/;
        open $fh, '<', $base . $file;
        $result = <$fh>;
        close $fh;
    }
    return $result;
}

sub contains {
    my($value, @array) = @_;
    for my $e(@array) {
        if ($e eq $value) {
            return 1;
        }
    }
    return 0;
}
