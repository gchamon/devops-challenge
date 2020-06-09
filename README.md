# DevOps Challenge
Stack completa de infraestrutura e desenvolvimento de um website em Docker na AWS.

## Introdução

Este projeto tem o propósito de implementar uma aplicação composta de um Frontend estático e um Backend executado em [Docker](https://www.docker.com/) na nuvem.

Para a aplicação, foram feitas modificações no projeto do [TodoMVC Vue.js](http://todomvc.com/) para que o mesmo utilizasse um backend para salvar o estado das listas.

O Backend foi implementado em Python, utilizando o framework [Falcon](https://falcon.readthedocs.io/en/stable/). Para desenvolvimento, o estado é salvo em disco. Para produção, esse estado é salvo em um Bucket S3.

O Frontend é servido utilizando [S3](https://aws.amazon.com/s3/) + [CloudFront](https://aws.amazon.com/cloudfront/), e o backend é executado utilizando o [Elastic Container Service](https://aws.amazon.com/ecs/) sobre [EC2](https://aws.amazon.com/ec2/) em múltiplas zonas de disponibilidade.

A Stack de infraestrutura é provisionada utilizando [Terraform 0.12.26](https://www.terraform.io/). O deploy dos serviços é realizado através de roles do [Ansible](https://docs.ansible.com/ansible/latest/index.html). O ambiente de desenvolvimento utiliza [docker-compose](https://docs.docker.com/compose/) para abstrair os serviços de frontend e backend.

## Decisões de projeto

### Desenvolvimento

Durante o desenvolvimento de uma aplicação, é interessante que nos aproximemos o máximo possível de nossa infraestrutura em produção. É, no entanto, impraticável possuir uma infraestrutura dedicada a cada desenvolvedor, pois esta pode ser extremamente cara e demandar muito tempo para provisionamento.

O interessante é que as dependências da aplicação sejam reprodutíveis. Desse modo, podemos assumir que as bibliotecas e aplicações disponíveis ao desenvolvedor durante desenvolvimento serão as mesmas que estarão disponíveis em produção.

Para que isso seja implementado, é utilizado docker. Em desenvolvimento é criado uma imagem base e a pasta local do desenvolvedor é mapeada para dentro do container, de modo que suas modificações se reflitam dentro dele. Para produção, produzimos uma imagem com tudo que a aplicação precisa rodar, todos os artefatos e dependências, e enviamos para o [Elastic Container Registry](https://aws.amazon.com/ecr/). Este assunto será abordado com maiores detalhes quando especificarmos a topologia da infraestrutura em nuvem.

### Cloud

Bugs e problemas não antevistos podem ser inseridos durante esse processo de desenvolvimento e escapar para a produção. De nada adianta termos um ambiente próximo da produção em desenvolvimento se não for possível realizar testes e experimentos centralizados, sem interferir com o que está sendo utilizado pelo cliente.

Para isso é necessário possuirmos um ambiente de homologação. Este ambiente precisa ser idêntico ao ambiente de produção, nos mínimos detalhes. Cada configuração de máquina, Load Balancer, certificado, rota, [CDN](https://en.wikipedia.org/wiki/Content_delivery_network) e permissões precisa ser as mesma. Com isso é possível identificar problemas de credenciais e permissões que potencialmente não afetam o desenvolvedor mas podem prejudicar o [SLA](https://pt.wikipedia.org/wiki/Acordo_de_n%C3%ADvel_de_servi%C3%A7o) do negócio.

O Terraform possui o conceito de módulos, unidades que definem um nicho de relações entre recursos em nuvem. Esses módulos podem ser reutilizados e efetivamente servem como abstrações lógicas. Para se obter o resultado de reprodução de infraestrutura, o ambiente de produção é tratado como um módulo. Dessa forma, para obtermos um novo ambiente de homologação, basta instanciar um novo módulo que uma infraestrutura identica é criada.

O projeto espera que seja utilizado o [Terraform Cloud](https://app.terraform.io/app). Essa é uma ferramenta gratuita produzida e disponibilizada pela [HashiCorp](https://www.hashicorp.com/) para executar planos do Terraform. Ela possui diversas vantagens, como centralização de estado da infraestrura, histórico de logs de aplicação, colaboração entre usuários, integração com pull requests do GitHub e execução em infraestrutura própria, localizada geograficamente próxima da `us-east-x` (Ohio ou Virgínia do Norte) da AWS. Sua localização é interessante pois reduz a latência de chamada de API para a AWS, reduzindo sensivelmente o tempo necessário para se atualizar as informações requeridas por um plano.

Para que o container do backend seja executado, optou-se por utilizar o Elastic Container Service. Nele, tarefas são definidas para executar imagens docker. Serviços, que são compostos por uma ou mais tarefas, se encarregam de delegar a execução deles a EC2 registradas no Cluster ECS ao qual pertence, e registrar as devidas portas no Load Balancer. O cluster é composto por duas EC2 em [regiões de disponibilidade](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/#Availability_Zones) distintas. Duas instâncias do nosso backend em dois containers separados rodam, dessa forma, em nessas duas EC2. Zonas de disponibilidades separadas são interessantes para reduzir a chance que uma indisponibilidade de serviço numa região possui de interromper o sistema em produçao.

O Elastic Container Service nos dá controle de quais permissões cada container herda, qual estratégia de deploy será empregada (Random, Distribuir por EC2, Distribuir por Zona...), qual proporção de recurso é dedicada para cada container, assim como toda a suite de configurações de um container como variáveis de ambiente, volumes etc...

As EC2 são controladas por um [Autoscaling Group](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html). O Autoscaling Group é capaz de definir as zonas de disponibilidades em que essas instancias serão lançadas, a quantidade de máquinas, o tipo e imagem a partir da qual essas máquinas serão lançadas, configurações internas (através do *user_data.sh*) e tipo de cobrança (on-demand ou spot). Para propósito desta demonstração serão lançadas instâncias tipo `t2.micro` que são inclusas no [free tier](https://aws.amazon.com/free/) da AWS.

O conteúdo estático do site (JavaScript, CSS e HTML) são servidos a partir de um bucket S3 por uma distribuição do CloudFront. O CloudFront é o serviço de distribuição de conteúdo da AWS. Ele é importante para aumentar a velocidade percebida do site, pois distribui o conteúdo a partir de pontos de presença [espalhados pelo globo](https://www.infrastructure.aws/).

Os certificados SSL são gerenciados pelo [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/) e não são retidos em nenhuma máquina que possa sofrer ataque a ter o conteúdo dos certificados vazados. A AWS se encarrega também da renovação e da disponibilidade desses certificados.

A infraestrutura utiliza o [Route 53](https://aws.amazon.com/route53/) para definição de DNS que faz referência a nossa distribuição do CloudFront. Ela espera que um domínio exista e produz quatro [Name Servers](https://en.wikipedia.org/wiki/Name_server) que precisam ser associados a um domínio real por meio de records tipo NS para que, por exemplo, certificados SSL sejam gerados e que o site seja accessível.

A chave para acesso SSH das instâncias do cluster ECS é depositada automaticamente num bucket definido. No entanto, o ECS possui um painel de monitoramento bastante compreensivo, com eventos, métricas e logs que torna acesso direto por terminal às máquinas desnecessário.

Abaixo encontra-se um diagrama da topologia da infraestrutura em nuvem:

![](https://github.com/gchamon/devops-challenge/raw/master/docs/images/overview.jpg)

Note que todos os elementos de infraestrutura podem ser utilizados no free tier:

| Nome | Free Tier (mensal) |
|--|--|
| EC2 | 750 horas |
| Load Balancer | 750 horas |
| S3 | 5 GB |
| CloudFront | 50 GB |
|  ||
 
### Deploy

O deploy é feito inteiramente por um playbook Ansible. Esse playbook executa duas roles, uma para popular o ECR e outra para popular o bucket S3 e invalidar o cache do CloudFront.

O ECR funciona como um repositório Docker, como o [Docker Hub](https://hub.docker.com/), porém ele se distigue por ter seu acesso controlado por políticas que podemos definir na AWS. Desse modo, ele funciona efetivamente como um repositório privado. Podemos, portanto, populá-lo com imagens contendo segredos e artefatos sensíveis que os mesmo só poderão ser acessados por recursos e por pessoas com credenciais sobre as quais possuimos total controle.

## Executando o projeto em desenvolvimento

### Pré-requisitos
- docker
- docker-compose

### Instalação

Para executar a aplicação localmente, é necessário compilar a imagem docker do backend e baixar as dependências do [npm](https://www.npmjs.com/) do frontend. Para isso, um script de conveniência foi escrito. Basta executar `install.sh` que esse processo é realizado. Note que não é necessário possuir o npm instalado. O script se vale do docker para baixar uma imagem nodejs alpine e, com ela, mapeando a pasta do frontend para dentro de si, instala o conteúdo necessário.

Uma vez compilada a imagem e baixadas as dependências podemos executar a aplicação. O frontend é servido por um [Nginx](https://www.nginx.com/) e o backend é executado pelo [gunicorn](https://gunicorn.org/), que é um servidor HTTP WSGI cujo falcon, nosso framework python, é compativel. Toda a aplicação é executada em container.

### Execução

Para executar a aplicação efetivamente, digite no terminal:

```
$ docker-compose up
```

Será exibido no terminal algo como:

```
Recreating devops-challenge_frontend_1 ... done
Starting devops-challenge_backend_1    ... done
Attaching to devops-challenge_backend_1, devops-challenge_frontend_1
frontend_1  | /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
frontend_1  | /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
frontend_1  | /docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
frontend_1  | 10-listen-on-ipv6-by-default.sh: Getting the checksum of /etc/nginx/conf.d/default.conf
frontend_1  | 10-listen-on-ipv6-by-default.sh: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
frontend_1  | /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
frontend_1  | /docker-entrypoint.sh: Configuration complete; ready for start up
backend_1   | [2020-06-09 00:22:19 +0000] [1] [INFO] Starting gunicorn 20.0.4
backend_1   | [2020-06-09 00:22:19 +0000] [1] [INFO] Listening at: http://0.0.0.0:5000 (1)
backend_1   | [2020-06-09 00:22:19 +0000] [1] [INFO] Using worker: sync
backend_1   | [2020-06-09 00:22:19 +0000] [7] [INFO] Booting worker with pid: 7
backend_1   | [2020-06-09 00:22:19 +0000] [8] [INFO] Booting worker with pid: 8
backend_1   | [2020-06-09 00:22:19 +0000] [9] [INFO] Booting worker with pid: 9
```

Indicando que o frontend e o backend estão sendo executados. Abra no browser `http://localhost` e a página do TodoMVC será exibida. Note que um arquivo `default.json` será criado na raíz da pasta `backend`. Esse arquivo possui o conteúdo salvo pelo backend. Desse modo você pode interagir com a lista, limpar o cache de sua sessão do browser e quando retornar a mesma lista será exibida com persistência.

![](https://github.com/gchamon/devops-challenge/raw/master/docs/images/frontend.png)

## Executando o projeto na AWS

### Pré-requisitos
O procedimento para execução do projeto em nuvem é um pouco mais envolvido. Precisaremos de:

- Uma conta na AWS, de preferência
