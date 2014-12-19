package Pylon;

use FindBin;
use Socket;
use Time::HiRes qw(gettimeofday tv_interval usleep);

sub new {
    my $package     = shift || return;
    my $class       = ref($package) || $package;
    my $params      = shift;
    my $self        = {};

    $self->{host} = $params->{host} || `/sbin/ifconfig eth1 | grep "inet addr" | cut -d':' -f 2 | cut -d ' ' -f 1` || 'localhost';
    $self->{port} = $params->{port} || 5555;
    $self->{debug} = $params->{debug} || 0;
    $self->{verbose} = $params->{verbose} || 0;

    bless($self, $class);
    return $self;
}

sub command {
    my $self = shift || return;
    my $command = shift || return;

    my ($iaddr, $paddr, $proto);

    $iaddr   = inet_aton($self->{host}) || die "no host: $self->{host}";
    $paddr   = sockaddr_in($self->{port}, $iaddr);

    $proto   = getprotobyname('tcp');
    socket(PSOCK, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
    connect(PSOCK, $paddr) || die "connect: $!";

    select(PSOCK);
    $| = 1;
    select(STDOUT);
    my $strlen = length($command);
    print PSOCK "$command|EOF\n";

    my $response = '';
    while (my $line = <PSOCK>) {
        if ($line eq "\n") {
            last;
        }
        $response .= $line;
    }
    close(PSOCK);

    chomp($response);
    return $response;
}

sub waitForIt {
    my $self = shift || return;
    my $args = shift || die;
    die unless (ref($args) eq 'HASH');

    my $step = $args->{step} || return;

    my $last = time();
    my $first = $last;
    print "waiting for the right time\n" if ($self->{verbose});
    while ((time() % $step) > 0 || $first == $last) {
        if (time() != $last) {
            print localtime(time())  . "\r" if ($self->{verbose});
            $last = time();
        }
        usleep(10000);
    }
    print localtime(time()) . "\n" if ($self->{verbose});
}

sub start {
    my $self = shift || return;
    print "starting pylon\n" if ($self->{verbose});
    my $command = "$FindBin::Bin/../init start";
    print "$command\n" if ($self->{debug});
    print `$command`;
    sleep 1;
}

sub stop {
    my $self = shift || return;
    print "stopping pylon\n" if ($self->{verbose});
    my $command = "$FindBin::Bin/../init stop";
    print "$command\n" if ($self->{debug});
    print `$command`;
}

sub servers {
    my $self = shift || return;

    my $list = $self->command("servers");
    my @servers = split(/\|/, $list);
    return @servers;
}

sub graphs {
    my $self = shift || return;
    my @servers = @_;
    return () unless (scalar(@servers));

    my $command = "graphs|" . join('|', @servers);
    my $list = $self->command($command);
    my @graphs = split(/\|/, $list);
    return @graphs;
}

sub options {
    my $self = shift || return;
    my $options;

    my $option_str = $self->command("options");
    foreach my $o (split(/ /, $option_str)) {
        my ($key, $value) = split(/=/, $o);
        $options->{$key} = $value;
    }
    return $options;
}

sub status {
    my $self = shift || return;
    my $status;

    my $status_str = $self->command("status");
    foreach my $o (split(/ /, $status_str)) {
        my ($key, $value) = split(/=/, $o);
        $status->{$key} = $value;
    }
    return $status;
}

sub array_average {
    @_ == 1 or die ('Sub usage: $average = average(\@array);');
    my ($array_ref) = @_;
    my $sum;
    my $count = scalar @$array_ref;
    foreach (@$array_ref) { $sum += $_; }
    return undef if ($sum == undef);
    return $sum / $count;
}

sub ensmoothen_graph_data {
    my $self = shift || return;
    my $graph_data = shift || return;
    my $start_time = shift;
    my $interval = shift;

    unless ($start_time && $interval) {
        my @time_list = sort keys %{$graph_data};
        $start_time = $time_list[0] unless($start_time);
        my $end_time = $time_list[scalar(@time_list) - 1];
        $interval = int(($end_time - $start_time ) /250);
    }
    my %avg = ();
    my $smooth_data;
    my %subs = ();

    my $time_mark = $start_time + $interval;
    foreach my $time (sort keys %{$graph_data}) {
        if ($time > $time_mark) {
            #print "$time_mark<br />\n";
            foreach my $sub_id (keys %avg) {
                $smooth_data->{$time_mark}{$sub_id} = array_average($avg{$sub_id});
            }
            %avg = ();
            $time_mark += $interval;
        }
        foreach my $sub_id (sort keys %{$graph_data->{$time}}) {
            push(@{$avg{$sub_id}}, $graph_data->{$time}{$sub_id});
            $subs{$sub_id}++;
        }
    }

    foreach my $sub_id (keys %avg) {
        $smooth_data->{$time_mark}{$sub_id} = array_average($avg{$sub_id});
    }

    foreach my $time (sort keys %{$smooth_data}) {
        foreach my $sub_id (keys %subs) {
            unless (defined($smooth_data->{$time}{$sub_id})) {
                $smooth_data->{$time}{$sub_id} = undef;
            }
        }
    }

    return $smooth_data;
}

1;
