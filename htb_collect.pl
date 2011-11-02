#!/usr/bin/env perl
#######################
# htb_collect.pl
# --------------
# parse the stat of a HTB policy
# from the tc command line
# convert them from bytes to bits
# store them into a RRD database
# --------------
# j. vehent - 11/2011
#######################
use strict;
use warnings;
use RRDs;
use Proc::Daemon;
use Data::Dumper;
# --- global variables, edit to meet your needs
#
# the interface where the TC policy is located
my $netcard = "eth0";
# location of the RRD database , no trailing slash
my $rrdloc = "/var/lib/htb_collect";
# frequency of the stat collection
my $updatefreq = 60;
# define a list of HTB classes to check
# the order matters, because of the RRD database
my @class_list=(100,200,300,400,999);





# --- you shouldn't have to edit below this point ---
#
my $DEBUG=1;
# stat storage structure
my %class_stats;
# rrd files
my %rrds;
# statistics to collect
my @stats_types = ("bits_sent","packet_sent","dropped","lended","borrowed","tokens","ctokens");

# check if RRD files exist at location or create them
foreach my $stat (@stats_types){
    my $rrd_file = "$rrdloc/$stat.rrd";
    unless (-f $rrd_file){
        print "$rrd_file does not exist. Creating it.\n";

        my $storage_type = "COUNTER";
        $storage_type = "GAUGE" if ($stat =~ /tokens/);

        my $seven_days= 7 * 86400 / $updatefreq; # 7 days of detailled records
        my $round_hour = 3600 / $updatefreq; # keep only one record per hour
        my $round_12h = 86400 / 2 / $updatefreq; # keep only one record per 12 hours

        my @datasources;
        for my $class (0 .. $#class_list){
            my $ds_string = "DS:$class_list[$class]:$storage_type:". $updatefreq * 10 .":U:U";
            push(@datasources,$ds_string);
        }

        RRDs::create("$rrd_file",'--start','now','--step',$updatefreq,
                    @datasources,
                    "RRA:AVERAGE:0.5:1:$seven_days",
                    "RRA:MAX:0.5:1:$seven_days",
                    "RRA:LAST:0.5:1:1",
                    "RRA:AVERAGE:0.5:$round_hour:1440",
                    "RRA:MAX:0.5:$round_hour:1440",
                    "RRA:AVERAGE:0.5:$round_12h:732",
                    "RRA:MAX:0.5:$round_12h:732"
                ) or die "RRD Create error: $!";
}

}
# do not daemonize in debug mode
Proc::Daemon::Init unless($DEBUG);

while(1)
{
    
    # reinit class values to 'U' at each iteration
    for my $class (0 .. $#class_list){
        foreach my $stat (@stats_types){
            $class_stats{$class_list[$class]}{$stat} = 'U';
        }
    }

    my $thissecond = time();
    print "\n\n--- iteration $thissecond ---\n" if ($DEBUG);

    # get statistics from command line
    open(TCSTAT,"tc -s class show dev $netcard |") || die "could not open tc command line\n$!";
            
    # look for specified classes into command line result
    while(<TCSTAT>)
    {
       chomp $_;
       # do we have class information in this line ?
       foreach my $class (0 .. $#class_list)
       {
          if ($_ =~ /^class htb \d\:$class_list[$class] parent/)
          {
             # If yes, parse the next line according to the tc stat format
             # I realize this is dirty, and could be largely optimized
             # but it works and I might fix it later
             my $nextline = <TCSTAT>;
             my @splitline = split(/ /,$nextline);
 
             # for the Sent value, convert bytes to bits
             $class_stats{$class_list[$class]}{bits_sent} = $splitline[2]*8;
             $class_stats{$class_list[$class]}{packet_sent} = $splitline[4];
             $splitline[7] =~ s/,//;
             $class_stats{$class_list[$class]}{dropped} = $splitline[7];

             #continue with next line
             $nextline = <TCSTAT>;
             $nextline = <TCSTAT>;
             chomp $nextline;
             @splitline = split(/ /,$nextline);
             $class_stats{$class_list[$class]}{lended} = $splitline[2];
             $class_stats{$class_list[$class]}{borrowed} = $splitline[4];
             
             #continue with next line
             $nextline = <TCSTAT>;
             chomp $nextline;
             @splitline = split(/ /,$nextline);
             $class_stats{$class_list[$class]}{tokens} = $splitline[2];
             $class_stats{$class_list[$class]}{ctokens} = $splitline[4];
             
          }
       }
    }
 
 
    # update line is :
    # <unix time>:<statistic class #1>:...:<statistic class #n>
    foreach my $stat (@stats_types){
        my $update_line = "$thissecond";
        for my $class (0 .. $#class_list){
           $update_line .= ":$class_stats{$class_list[$class]}{$stat}";
        }
        my $rrd_file = "$rrdloc/$stat.rrd";
        RRDs::update $rrd_file, "$update_line";
        if ($DEBUG){ print "$stat = $update_line\n";}
    }
 
    if ($DEBUG){
        for my $class (0 .. $#class_list){
            print "class $class_list[$class]: ";
            foreach my $stat (keys %{$class_stats{$class_list[$class]}}){
                print "$stat=$class_stats{$class_list[$class]}{$stat} "
            }
            print "\n";
        }
    }
    # sleep until next period
    sleep $updatefreq;
}
