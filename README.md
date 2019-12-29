# nomongo
Response to NoSQL adopters

Este projeto visa resolver a questão de desempenho referente a adoção de soluções como o MongoDB para implementações do tipo Rest API em JSON

Utiliza tecnologias validadas e robustas, como o banco de dados PostgreSQL, Apache, Perl, utilizando um código enxuto e performático.

NoMongo é uma Rest API. Antes de realizar solicitações é necessário obter um token por meio de autenticação com usuário e senha. No projeto, esse token recebeu o nome de sID. Para obter esse token, é necessário enviar, via POST um usuário e senha válidos, usando JSON ou o tradicional padrão chave e valor, de formulários HTTP, para o endereço /signin. A resposta a solicitação é um JSON com os dados do usuário autenticado e o valor do sID ou uma mensagem de falha de autenticação.

O token deve ser enviado no cabeçalho HTTP das requisições. A primeira requisição sugerida é referente ao menu que será mostrado no frontend da aplicação. Ele pode ser obtido por meio do endereço /menu.

As requisições são mapeadas para o Rest API de acordo com o método HTTP:

GET = Usado para consultar as coleções, sendo o primeiro elemento da URI a tabela/coleção que se deseja consultar e após, opcionalmente, valores de filtros;

POST = Utilizado para inclusão de dados, aceita objeto JSON ou padrão tradicional chave/valor;

PUT = Utilizado para alteração de dados. É necessário enviar a chave primária do registro/coleção, sendo que na conversão para o SQL essa informação é identificada baseado na estrutura da tabela. Como padrão, adotamos o uso de "id" como nome de campo para a chave primária, mas é opcional;

DELETE = Utilizado para exclusão de de dados e deve ser informado o valor da chave na URI.


### Instalação versão em container:
Proceda com os seguintes comandos:

    $ git clone https://github.com/codevenger/nomongo
    $ cd nomongo
    $ docker build -t nomongo .
    $ docker run -it -v $(pwd)/frontend:/var/www/nomongo/frontend -v $(pwd)/backend:/var/www/nomongo/backend --name nomongo -p 80:80 -d nomongo
    $ docker exec -it nomongo sed -i -e "s/# pt_BR.UTF-8/pt_BR.UTF-8/" /etc/locale.gen
    $ docker exec -it nomongo dpkg-reconfigure --frontend=noninteractive locales
    $ docker exec -it nomongo update-locale LANG=pt_BR.UTF-8
    $ docker exec -it nomongo sed -i 's|C.UTF-8|pt_BR.UTF-8|gm' /etc/postgresql/10/main/postgresql.conf
    $ docker exec -it nomongo pg_dropcluster --stop 10 main
    $ docker exec -it nomongo pg_createcluster --locale pt_BR.UTF-8 --start 10 main
    $ docker exec -it nomongo service postgresql restart
    $ docker exec -it nomongo su -c "psql < /var/www/nomongo/backend/database.sql" postgres
    $ docker cp nomongo.d nomongo:/etc/
    $ docker exec -it nomongo service apache2 start
 
    
Por fim, abra com seu navegador preferido o endereço [http://localhost/](http://localhost)

