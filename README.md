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


