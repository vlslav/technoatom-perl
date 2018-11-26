#!/usr/bin/env perl

use 5.016;
use warnings;
# perldoc -f time
# perldoc -f localtime
# perldoc -f sprintf
use Time::Local 'timelocal'; # может помочь в вычислении time для заданного месяца

if (@ARGV == 1) {
	my ($month) = @ARGV;
	if ($month <= 12 && $month >= 1){
		calendar($month);
	}
	else {
		die "Month is out of range";
	}
}
elsif (not @ARGV) {
	calendar((localtime)[4] + 1);
}
else {
	die "Bad arguments";
}

sub calendar {
    my $month = (shift) - 1;
    my $year = (localtime)[5] + 1900;
    my @month_days = qw(31 28 31 30 31 30 31 31 30 31 30 31);
    my @names = qw(January February March April May June July August September October November December);
    # Проверка на високосность
    if ($year % 4 == 0 || $year % 400 == 0) {
    	$month_days[1]++;
    }
    # Начинаем отрисовку календаря
    my $cal = "     $names[$month] $year\n";
    $cal .= " Mo Tu We Th Fr Sa Su\n";
    my $time = timelocal(0, 0, 0, 1, $month, $year);
    my $weekday = (localtime $time)[6];
    # Учитываем, что неделя в России начинается с понедельника
    if ($weekday == 0) {
    	$weekday = 6;
    }
    else {
    	$weekday--;
    }
    $cal .= "   " x ($weekday);
    my $month_day = 1;
    while ($month_day <= $month_days[$month]) {
        $cal .= sprintf "%3s", $month_day++;
        if (($weekday + $month_day - 1) % 7 == 0) {
        	$cal .= "\n";
        }
    }
    print $cal . "\n";
}