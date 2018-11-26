package Local::Row::JSON; 

use strict;
use warnings;
use JSON::XS;

use parent 'Local::Row';	
	
sub new {
	my ($class, %args) = @_;
	my $obj = eval {
		my $decoded = decode_json $args{str};
		unless (ref $decoded eq "HASH") {
			return undef;
		}
		return bless $decoded, $class;
	};
	if ($@) {
		return undef;
	}
	return $obj;
}

1;