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

use constant false => 1==0;
use constant true => not false;

$query = new CGI;
$sid = $ENV{'AUTHORIZATION'};
if($sid eq "") {
    $sid = $ENV{'HTTP_SID'};
} else {
    $sid =~ s/^sid[\s|=|:]+//;
}
if($sid eq "" || $sid eq "undefined") {
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

my $req = $ENV{'REQUEST_URI'};

# remove diretório SYS, caso exista
$req =~ s/^\/sys\///;
($tab) = ($req =~ /^(\S+)\//);
if($tab eq "") {
    ($tab) = ($req =~ /^(\S+)$/);
}

# Limpa recurso
if($tab =~ /^\//) {
    $tab =~ s/\///;
}
if($tab =~ /\?/) {
    $tab =~ s/\?.*//;
}


# Testa se requisição é válida
if($ENV{'REQUEST_METHOD'} eq "OPTIONS") {
    say('ok');
    exit;
} elsif($ENV{'REQUEST_METHOD'} eq "DELETE") {
    if($tab !~ /^[a-zA-Z0-9\_\-\/]+$/) {
        error('Caracteres inválidos no nome do recurso');
    }
} else {
    if($tab !~ /^[a-zA-Z0-9\_\-]+$/) {
        error('Caracteres inválidos no nome do recurso');
    }
}




# Verifica se está tentando acessar sem estar logado
if($this =~ /signin$/) {
    # Não verifica o login
    return true;
} elsif($sid eq "" || $ip eq "") {
    deny($sid);
} else {
    $sth = $dbh->prepare(qq(select * from system.users_signin where sid = ? and now() < ("end" + interval '$timeout seconds') ));
    $sth->execute($sid);
    if($dbh->err ne "") {
        error("Falha em localizar o sid no log do Login!");
    }
    if($sth->rows() > 0) {
        $row = $sth->fetchrow_hashref;
        $user{code} = $row->{'user'};
        $user{entity} = $row->{'entity'};
        $rv = $dbh->do(qq(update system.users_signin set "end" = now() where sid = '$sid' and ip = '$ip'));
        if($dbh->err ne "") {
            error("Falha em atualizar o sid no log do Login");
        }
        
        # gera variaveis de ambiente do usuario
        $sth = $dbh->prepare(qq(select users.*, users.id as id, users.name as name from system.users users where users.id = '$user{code}'));
        $sth->execute();
        if($dbh->err ne "") { 
            error("Não foi possível acessar os dados do usuário");
        } elsif($sth->rows() == 1) {
            $row = $sth->fetchrow_hashref;
            $user{username} = $row->{'username'};
            $user{name} = $row->{'name'};
        }
        
        if($user{entity} =~ /^\d+$/) {
            $sth = $dbh->prepare(qq(select e.*, g.id as group_id, g.descrp as group_name from system.users_groups d join entities e on d.entity = e.id join system.groups g on d.group = g.id where d.user = ? and e.disabled is null order by e.dt_ins limit 1));
            $sth->execute($user{code});
            if($dbh->err ne "") {
                error("Falha em localizar a organização a qual o usuário pertence!");
            }
            if($sth->rows() > 0) {
                $row = $sth->fetchrow_hashref;
                $user{entity} = $row->{'id'};
                $user{group} = $row->{'group_id'};
                $entity{id} = $row->{'id'};
                $entity{name} = $row->{'name'};
                $entity{alias} = $row->{'alias'};
                $group{id} = $row->{'group_id'};
                $group{name} = $row->{'group_name'};
            } else {            
                error("Não foi encontrada nenhuma organização para o usuário!");
            }
        }
      
    } else {
        deny($sid);
    }
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

sub say {
    my ($msg) = @_;
    $msg = JSON->new->allow_nonref->encode(encode_entities($msg));
  
    # Inicializa JSON como resposta
    print $query->header(-type => "application/json", -charset => "utf-8");
    print qq({\n"status" : 200,\n);
    print qq("message" : ).$msg;
    print qq(\n});

    if($ENV{'REQUEST_METHOD'} ne "GET" && $dbh) {
        $dbh->commit();
    }
    exit;
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

sub deny {
    my ($sid) = @_;
    
    # Inicializa JSON como resposta
    print $query->header(-type => "application/json", -charset => "utf-8", -status => "401 Unauthorized");
    # Executa no caso de acesso inválido
    print qq({\n"status" : 401,\n);
    if($sid ne "") {
        print qq("sid" : "$sid",\n);
    }
    print qq("message" : "Acesso negado"\n});
    exit;
}

