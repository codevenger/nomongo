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

$req = $ENV{'REQUEST_URI'};

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
    $dbh->{AutoCommit} = 0;

    # força UTF-8 nos resultados das consultas
    $dbh->{pg_enable_utf8} = 1;
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
    print $msg;
    
    if($ENV{'REQUEST_METHOD'} ne "GET" && $dbh) {
        $dbh->commit();
    }
    exit;
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

sub chktbl {
    my ($tab) = @_;
    my $schema = 'public';
    if($tab eq 'users' || $tab eq 'groups' || $tab eq 'users_groups' || $tab eq 'languages') {
        $schema = 'system';
    }
    
    my $sth = $dbh->prepare(qq(select * from information_schema.tables where table_schema = ? and table_name = ?));
    $sth->execute($schema, $tab);
    if($dbh->err ne "") {
        error("Falha em localizar a recurso requisitado");
    }

    if($sth->rows() == 0) {
        $sth = $dbh->prepare(qq(select * from pg_class where relkind = 'm' and oid::regclass::text = ?));
        $sth->execute($tab);
        if($dbh->err ne "") {
            error("Falha em localizar a recurso requisitado");
        }    
        if($sth->rows() == 0) {
            error("Recurso $tab não encontrado");
        }
    }

    if($user{group} eq '') {
        error("Falha em identificar o grupo do usuário");
    } else {
        # Verifica se tem direito de acesso
        $sth = $dbh->prepare(qq(select * from system.groups_tables where "group" = '$user{group}' and "table" = ? and level > 0));
        $sth->execute($tab);
        if($dbh->err ne "") {
            error("Falha em verificar os direitos de acesso ao recurso requisitado ".$dbh->errstr);
        }
        if($sth->rows() == 0) {
            error("Sem direito de acesso");
        }
    }

}
    
    
sub getfk {
    my ($tab) = @_;
    
    my $sth = $dbh->prepare(qq(select tc.constraint_name, tc.table_name, tc.constraint_name, kcu.column_name, ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name FROM information_schema.table_constraints AS tc JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name WHERE constraint_type = 'FOREIGN KEY' AND tc.table_name = ?));
    $sth->execute($tab);
    if($dbh->err ne "") {
        error("Falha ao encontrar as chaves estrangeiras ao popular recurso requisitado");
    }
    if($sth->rows() > 0) {
        while(my $row = $sth->fetchrow_hashref) {
            $fk{$row->{'table_name'}}{$row->{'column_name'}}{'tab'} = $row->{'foreign_table_name'};
            $fk{$row->{'table_name'}}{$row->{'column_name'}}{'col'} = $row->{'foreign_column_name'};
            if(! $fk{$row->{'foreign_table_name'}}) {
                &getfk($row->{'foreign_table_name'});
            }
        }
    }
    return true;
}


sub getpk {
    my ($tab) = @_;
    my $p = '';
    
    if($tab eq 'users' || $tab eq 'groups' || $tab eq 'users_groups' || $tab eq 'languages') {
        $tab = 'system.'.$tab;
    }
    
    # Lista a chave primária da tabela
    $sth = $dbh->prepare(qq(select a.attname, format_type(a.atttypid, a.atttypmod) as data_type from pg_index i join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any(i.indkey) where i.indrelid = '$tab'::regclass and i.indisprimary));
    $sth->execute();
    if($dbh->err ne "") {
        error("Falha ao encontrar a chave primária do recurso requisitado");
    }
    if($sth->rows() > 0) {
        while($row = $sth->fetchrow_hashref) {
            $p .= $tab.'.'.$row->{'attname'}.', ';
        }
    }
    $p =~ s/, $//;
    return $p;
}

