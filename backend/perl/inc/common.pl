#!/bin/perl

# Ativa o modo UTF8
binmode STDOUT, ":encoding(utf8)";
use utf8;

use JSON;
use HTML::Entities;
use URI::Escape;
use Encode qw( decode_utf8 );

use CGI;
use DBI;
use DBD::Pg;

$query = new CGI;
$sid = $ENV{'AUTHORIZATION'};
if($sid eq "") {
    $sid = $ENV{'HTTP_SID'};
} else {
    $sid =~ s/^sid[\s|=|:]+//;
}
if($sid eq "") {
    $sid = &get("sid");
}
if($sid eq "") {
    my $uri = $ENV{'REQUEST_URI'};
    if($uri =~ /[\?|&]+sid=([0-9]+)/) {
        $sid = $1;
    }
}
if($sid eq "null") {
    $sid = "";
}
$ip = $ENV{'REMOTE_ADDR'};
$this = $ENV{'SCRIPT_NAME'};

$timeout = 36000; # (60 sec * 60 min * 10 horas);

# Inicializa conexão ao banco de dados
&connect;

if($ENV{'REQUEST_METHOD'} eq "OPTIONS") {
    say('ok');
    exit;
}






return true;




sub connect {
	require "/etc/nomongo.d/credentials.pl";
    $dbh = DBI->connect("DBI:Pg:dbname=$db;host=$server;port=$port",$user,$pass) || die "Erro na conexão!!! $!\n\n";
    
    # desabilita Autocommit
    $dbh->{AutoCommit}=0;

    # força UTF-8 nos resultados das consultas
    $dbh->{pg_enable_utf8}=0;
    $dbh->do("SET client_encoding TO 'UTF8';");
    
    # seta tratamento de datas para portugues
    $dbh->do("SET lc_time = 'pt_BR.UTF8';");
}

sub get {
    my ($p) = @_;
    # Tenta o metodo GET ou POST
    my $x = $query->param($p);
    if($x eq "") {
        $x = $query->url_param($p);
    }
    # Tenta por JSON
    if($x eq "") {
        my $d = $query->param("POSTDATA");
        if($d eq "") {
            $d = $query->param("PUTDATA");
        }
        if($d eq "") {
            $d = $query->param("DELETEDATA");
        }
        if($d =~ /$p/m) {
            my $json = decode_json($d);
            $x = $json->{$p};
            if($x eq "") {
                $x = "null";
            }
        }
    }
    $x =~ s/&/&amp;/g;
    $x =~ s/"/&quot;/g;
    $x =~ s/'/&apos;/g;
    $x =~ s/</&lt;/g;
    $x =~ s/>/&gt;/g;
    return $x;
}

sub say_json {
    my ($msg) = @_;
    
    my ($status) = ($row->{res} =~ /['|"]status['|"]\s?[=|:]+\s?(.*)$/i);
    print $query->header(-type => "application/json", -charset => "utf-8", -status => $status);
    print decode_utf8($msg);
}

sub error {
    my ($msg) = @_;
    $msg = JSON->new->allow_nonref->encode(encode_entities($msg));
  
    # Inicializa JSON como resposta
    print $query->header(-type => "application/json", -charset => "utf-8", -status => "400 Bad Request");
    print qq({\n"status" : 400,\n);
    print qq("message" : ).$msg;
    print qq(\n});

    if($ENV{'REQUEST_METHOD'} ne "GET" && $dbh) {
        $dbh->rollback();
    }
    exit;
}

