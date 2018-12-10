package Notes;
use Dancer2;
use Dancer2::Plugin::Database;
use Data::Dumper;
use HTML::Entities;
use List::Util "uniq";
use Digest::MD5 'md5_hex';
use utf8;

our $VERSION = '0.1';
our @chars = ("A".."Z", "a".."z", 0..9);
my $up_dir = 'notes';
sub get_up_dir {
    return $up_dir . "/";
}
sub salt {
    my $string;
    $string .= $chars[rand @chars] for 1..8;
    return $string;
}

sub check_in_db {
    my $login = shift;
    my $sth = database->prepare("SELECT COUNT(*) FROM user WHERE username = ?");
    $sth->execute($login);
    if ($sth->fetchrow) {
        return 1;
    }
    return 0;
}

sub check_usname_and_passwd {
    my ($username, $passwd) = @_;
    unless ($username =~ /\w{4,}/) {
        return "The username must be at least 4 characters long";
    }
    unless ($passwd =~ /\w{6,}/) {
        return "The passwoed must be at least 6 characters long";
    }
    return;
}

sub check_text {
    my ($len, $users) = @_;

    if (!$len) {
        return "Empty text";
    }
    if ($len > 10240) {
        return "Text too large";
    }
    my @bad_users;
    for (@{$users}) {
        push(@bad_users, $_) if ($_ !~ /\w{6,}/);
    }
    if (@bad_users) {
        return (join ",", @bad_users) . " - wrong usernames";
    }
}

hook before => sub {
    if (!session('user') && request->dispatch_path !~ /login|registration/ ) {
        redirect "/login?path=" . request->dispatch_path;
    }
};

get '/' => sub {
    my $user = session('user');
    my $sth = database->prepare("SELECT file, title FROM record where author = ?");
    $sth->execute($user);
    my $my_notes = $sth->fetchall_arrayref({});
    for (@{$my_notes}) {
        $_->{ref} = '/' . $_->{file};
        delete $_->{file};
    }
    $sth = database->prepare("SELECT record  FROM record_spectator where spectator = ?");
    $sth->execute($user);
    my $other_notes = $sth->fetchall_arrayref({});
    $sth = database->prepare("SELECT title, file FROM record WHERE file IN (?" .( ",?" x (@{$other_notes} - 1)) . ")");
    $sth->execute(map {$_->{record}}@{$other_notes});
    $other_notes = $sth->fetchall_arrayref({});
    foreach (@{$other_notes}) {
        $_->{ref} = $_->{file};
        delete $_->{file};
    }
    template 'index' => { 'title' => 'Notes', my_notes => $my_notes, other_notes => $other_notes, username => $user };
};


get '/login' => sub { 
    if ( session('logged_in') ) { redirect '/'; }
    template 'login.tt' , {'title' => "login"}, {layout => "log.tt"};
};

post '/login' => sub {
    my $err;
    my $username = params->{username};
    my $passwd = params->{password};
    $err = check_usname_and_passwd($username, $passwd);
    $err //= (check_in_db($username)) ? undef : "user doesn't exists";

    unless ($err) {
    	my $sth = database->prepare("SELECT password, salt FROM user where username = ?");
        $sth->execute($username);
        my $href = $sth->fetchrow_hashref;
        my $password = md5_hex( md5_hex($passwd) . $href->{salt} );
        if ($password eq $href->{password}) {
            session 'user' => $username;
            return redirect param('path') || "/";
        }
        $err = "Wrong password";
    }
    template 'login.tt' , {'title' => "login", 'err' => $err}, {layout => "log.tt"};
};

get '/registration' => sub {
    if ( session('logged_in') ) { redirect '/'; }
    template 'registration.tt' , {'title' => "Registration"}, {layout => "log.tt"};
};

post '/registration' => sub {
    my $err;
    my $username = params->{username};
    my $passwd = params->{password};

    $err = check_usname_and_passwd($username, $passwd);
    $err //= (check_in_db($username)) ? "user already exists" : undef;
    unless ($err) {
    	my $sth = database->prepare("INSERT INTO user (username, password, salt) VALUES ( ?, ?, ?)");
        my $salt = salt;
        my $password = md5_hex( md5_hex($passwd) . $salt );
        unless ($err = check_in_db($username)) {
            $sth->execute($username, $password, $salt);
            session 'user' => $username;
            return redirect '/';
        }
    }
    template 'registration.tt' , {'title' => "Registration", 'err' => $err}, {layout => "log.tt"};
};

get qr"/[A-Za-z0-9]{8}" => sub {
    my $file = request->dispatch_path;
    substr($file, 0, 1) = '';
    my $sth = database->prepare("SELECT * FROM record where file = ?");
    unless ($sth->execute($file)) {
        response->status(404);
        return;
    }
    my $db_res = $sth->fetchrow_hashref();
    if (session('user') ne $db_res->{author} )   {
        my $sth_n = database->prepare("SELECT COUNT(*) FROM record_spectator WHERE ((record = ?) AND (spectator = ?))");
        $sth_n->execute($file, session('user'));
        if (not $sth_n->fetchrow) {
            response->status(403);
            return;
        }
    }
    my $fh;
    unless (open($fh, '<:utf8', get_up_dir . $file)) {
        response->status(404);
        return;
    }
    my @text = <$fh>;
    close($fh);
    for (@text) {
        s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
        s/^ /&nbsp;/g;
    }
    if (session('user') ne $db_res->{author} )   {
        return template 'note.tt' => {text => \@text, title => $db_res->{title}};
    }
    else {
        return template 'note.tt' => {text => \@text, title => $db_res->{title}, id => $file};
    }
    
};

post '/add' => sub {
   my $text = params->{text};
   $text = encode_entities($text, '<>&"');
   my $title = params->{title}||'Note';
   $title = encode_entities($title, '<>&"');
   my $users = params->{users};
   $users = encode_entities($users, '<>&"');
   my $err = '';
   my @users = uniq split /\s*,\s*/, $users;
   $err = check_text(length($text), \@users);
   unless ($err) {
        my $sth = database->prepare('INSERT INTO record (author, title, file) VALUES ( ?, ?, ?)');
        my $file = '';
        my $author = session('user');
        my $try_count = 10;
        while (!$file or -f get_up_dir . $file) {
            unless (--$try_count) {
                $file = undef;
                last;
            }
            $file = salt;
            $file = undef unless $sth->execute($author, $title, $file);
        }
        unless ($file) {
            die "Try latter";
        }
        my $fh;
        unless (open($fh, '>', get_up_dir . $file)) {
            die "Internal error ", $!;
        }
        print $fh $text;
        close($fh);

        $sth = database->prepare("INSERT INTO record_spectator (record, spectator) VALUES ( '$file', ?)");
        for (@users) {
            $sth->execute($_) if ($_ ne $author);
        }
        redirect '/' . $file;
    }
    template 'add.tt' , { title => "New Note", err => $err, text => $text, title => $title, users => $users};
};

get '/add' => sub {
    template 'add.tt';        
};

get "/edit" => sub {
    my $file = params->{id};
    unless ($file) {
        redirect '/';
    }
    my $sth = database->prepare("SELECT * FROM record WHERE file = ?");
    unless ($sth->execute($file)) {
        response->status(404);
        return;
    }
    my $db_res = $sth->fetchrow_hashref();
    if (session('user') ne $db_res->{author} )   {
        my $sth_n = database->prepare("SELECT COUNT(*) FROM record_spectator WHERE ((record = ?) AND (spectator = ?))");
        $sth_n->execute($file, session('user'));
        if (not $sth_n->fetchrow) {
            response->status(403);
            return;
        }
    }
    my $fh;
    unless (open($fh, '<:utf8', get_up_dir . $file)) {
        response->status(404);
        return;
    }
    my @text = <$fh>; 
    close($fh);
    return template 'edit.tt', {title => $db_res->{title}, text => \@text, id => $file};   
};

post "/edit" => sub {
    my $file = params->{id};
    my $text = params->{text};
    $text = encode_entities($text, '<>&"');
    my $title = params->{title}||'Note';
    $title = encode_entities($title, '<>&"');
    my $err = '';
    if (!length($text)) {
        $err = "Empty text";
    }
    if (length($text) > 10240) {
        $err = "Text too large";
    }
    unless ($err) {
        my $fh;
        unless (open($fh, '>', get_up_dir . $file)) {
            die "Internal error ", $!;
        }
        print $fh $text;
        close($fh);
        my $sth = database->prepare("UPDATE record SET title = ?");
        $sth->execute($title);
        redirect "/" . $file;
    }
    template 'edit.tt' , { err => $err, text => $text, title => $title};
};

get "/remove" => sub {
    my $file = params->{id};
    my $sth = database->prepare("SELECT * FROM record where file = ?");
    unless ($sth->execute($file)) {
        response->status(404);
        return;
    }
    my $db_res = $sth->fetchrow_hashref();
    if (session('user') ne $db_res->{author} )   {
        my $sth_n = database->prepare("SELECT COUNT(*) FROM record_spectator WHERE ((record = ?) AND (spectator = ?))");
        $sth_n->execute($file, session('user'));
        if (not $sth_n->fetchrow) {
            response->status(403);
            return;
        }
    }
    my $fh;
    unless (open($fh, '<:utf8', get_up_dir . $file)) {
        response->status(404);
        return;
    }
    close($fh);
    $sth = database->prepare("DELETE FROM record WHERE file = ?");
    my $sth1 = database->prepare("DELETE FROM record_spectator WHERE record = ?");
    $sth->execute($file);
    $sth1->execute($file);
    redirect "/";
};

get '/logout' => sub {
    app->destroy_session;
    redirect '/login';
};

true;
