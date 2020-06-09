
# DevOps Challenge
Stack completa de infraestrutura e desenvolvimento de um website em Docker na AWS.

## Introdução

Este projeto tem o propósito de implementar uma aplicação composta de um Frontend estático e um Backend executado em [Docker](https://www.docker.com/) na nuvem.

Para a aplicação, foram feitas modificações no projeto do [TodoMVC Vue.js](http://todomvc.com/) feito por [Evan You](http://evanyou.me) para que o mesmo utilizasse um backend para salvar o estado das listas.

O Backend foi implementado em Python, utilizando o framework [Falcon](https://falcon.readthedocs.io/en/stable/). Para desenvolvimento, o estado é salvo em disco. Para produção, esse estado é salvo em um Bucket S3.

O Frontend é servido utilizando [S3](https://aws.amazon.com/s3/) + [CloudFront](https://aws.amazon.com/cloudfront/), e o backend é executado utilizando o [Elastic Container Service](https://aws.amazon.com/ecs/) sobre [EC2](https://aws.amazon.com/ec2/) em múltiplas zonas de disponibilidade.

A Stack de infraestrutura é provisionada utilizando [Terraform 0.12.26](https://www.terraform.io/). O deploy dos serviços é realizado através de roles do [Ansible](https://docs.ansible.com/ansible/latest/index.html). O ambiente de desenvolvimento utiliza [docker-compose](https://docs.docker.com/compose/) para abstrair os serviços de frontend e backend.

### Estrutura do projeto

O projeto é subdividido da seguinte forma:

```
$ lsd --tree --depth 1
  .
├──   backend
│  └──   controllers
├──   cloud-infrastructure
│  ├──   modules
│  ├──   production
│  └──   shared
├──   deployment
│  ├──   ecr
│  └──   frontend
└──   frontend
    └──   js
```

- backend: código da API em Python
- cloud-infrastructure: código do terraform. Subdivide-se em módulos, com a definição dos módulos utilizados, production, que possui a instância do ambiente de produção, e shared, que possui recursos comuns entre ambientes.
- deployment: carrega as roles do ansible
- frontend: possui os arquivos de HTML, CSS e JavaScript relativos ao frontend. Note a ausência da pasta `node_modules`. Ela será inicializada mais a frente.

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

Como utilizaremos um único DNS para este projeto, o CloudFront deverá redirecionar por meio de regra de origin requisições para a path `/api` para o Load Balancer, que por sua vez entregará essas requisições para os respectivos containers para que ela possa ser tratada. Desse modo, para toda a requisição que não possuir a path `/api`, o CloudFront buscará no bucket de arquivos estáticos do frontend, pois esse bucket é seu origin padrão.

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

### Terraform

O projeto do Terraform, que se encontra na pasta `cloud-infrastrucutre` segue o modelo de [composição de infraestrura](https://www.terraform-best-practices.com/key-concepts#composition). Grosso modo, é um modelo que segmenta a infraestrurua, deixando em um mesmo estado apenas os recursos que realmente são necessários. Com isso ganhamos eficiência em deploy, pois com uma infraestrutura segmentada existem menos recursos para serem atualizados em tempo de *plan*.

Também reduzimos o *blast radius* (ou raio de "explosão"), que é a lista efetiva de recursos que podem ser afetados por uma intervenção mal planejada. Dessa forma, se a infraestrutura *shared*, *production* e outros eventuais ambientes como *staging* estiverem em seus respectivos workspaces, uma má implementação afetaria primeiramente o ambiente *staging*, aumentando as chances de ser visto e corrigido antes de afetar o ambiente de produção.

Para se alcançar este efeito, importamos dados compartilhados entre os workspaces. O workspace *production* depende da infraestrutura de rede, que é única, compartilhada entre todos os ambientes. Para isso, é importado o estado de *shared* através do Data Source `terraform_remote_state`, que recebe o tipo de backend e sua configuração de acesso.

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

- Uma conta no [Terraform Cloud](https://app.terraform.io/app)
- Uma conta na AWS, de preferência com créditos free tier
- Um domínio ativo
- [Terraform CLI](https://www.terraform.io/downloads.html)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- Um *fork* deste repositório em sua conta GitHub

### AWS

Ao criar uma conta na AWS, você terá apenas a própra conta raíz (root account). Com ela faremos dois usuários IAM, mas primeiro certifique de que sua senha da root account é forte e que o [MFA está ativo](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable_virtual.html).

Com a root account, crie dois usuários, um para você entrar pelo console e outro para o terraform e associe aos dois permissão da policy *AdministratorFullAccess*.

Para o usuário de console, crie uma senha e para o usuário do terraform crie uma chave de acesso de API. Precisaremos dela no Terraform Cloud.

Digite no console ``

### Terraform Cloud

#### Configuração

Configure uma conta no Terraform Cloud. Crie também um token de acesso e [configure a CLI](https://www.terraform.io/docs/commands/cli-config.html) como descrito. Quando terminar, você deverá ter o arquivo `~/.terraformrc` com a seguinte estrutura:

```r
credentials "app.terraform.io" {
  token = "xxxxxx.atlasv1.zzzzzzzzzzzzz"
}
```

Ao logar no Terraform Cloud, crie uma organização chamada `devops-challenge`. Com isso será possível inicializar os workspaces.

Navegue para a pasta `cloud-infrastructure/shared` e inicialize o terraform com `terraform init`. Faça o mesmo em `cloud-infrastructure/shared`. Dois workspaces serão criados no Terraform Cloud.

Esses workspaces precisam de três variáves do terraform configuradas e duas variáveis de ambiente. Vá no terraform cloud, selecione a organização criada, e selecione o workspace `shared`. No topo, clique em `Variables`. O ambiente necessita que seja configurado com as seguintes variáveis:

- **Terraform Variables**

| Key | Value  |
|--|--|
| aws_region | recomendado: `us-east-2` |
| zone_name | devops-challenge.seudomínio.com |
| project_name* | seu-nome-devops-challenge |

*A variável `project_name` é utilizada para dar nome aos buckets estáticos de produção. Como os buckets são regionais, mas são indexados globalmente, seus nomes precisam ser únicos. Escolha um nome, portanto que seja único para o seu projeto.

- **Environment Variables**

| Key | Value  | Sensitive |
|--|--|--|
| AWS_ACCESS_KEY_ID | Access Key ID do usuário IAM Terraform* | Não |
| AWS_SECRET_ACCESS_KEY | Secret da Access Key do usuário IAM Terraform* | Sim |

*Esses usuários foram criados na conta AWS no console, no passo anterior.

Vá em `Settings > Version Control` e associe sua conta GitHub ao Terraform cloud e selecione o *fork* deste repositório em sua conta.

Vá em `Settings > General` e em `Terraform Working Directory` preencha com `cloud-infrastructure/shared`

Para o workspace `production`:

- **Terraform Variables**

| Key | Value  |
|--|--|
| aws_region | recomendado: `us-east-2` |
| domain_name | devops-challenge.seudomínio.com |
| environment_name | production |
| project_name | seu-nome-devops-challenge |


- **Environment Variables**

| Key | Value  | Sensitive |
|--|--|--|
| AWS_ACCESS_KEY_ID | Access Key ID do usuário IAM Terraform* | Não |
| AWS_SECRET_ACCESS_KEY | Secret da Access Key do usuário IAM Terraform* | Sim |

Faça a mesma associação com o GitHub e em `Terraform Working Directory` preencha com `cloud-infrastructure/production`.

Neste momento será possível aplicar a primeira parte da infraestrutura.

#### Deploy da infraestrutura - Shared

Primeiro vá no workspace `shared` e se não houver nenhuma execução em processo, execute uma manualmente. O Terraform Cloud divide cada intervenção de infraestrutura em `plan` e `apply`. No estágio `plan`, uma descrição do que será feito, com todas as configurações de cada recurso a ser criado.

Quando o estágio de `plan` for concluído na infraestrutura `shared`, o resumo deve mostrar `Plan: 19 to add, 0 to change, 0 to destroy`. Aprove o plan, e a infraestrutura base será criada.

Quando o estágio de `apply` terminar, um output extenso em letras verdes será impresso na tela. Nele, busque por `route53_delegation_set` para que possamos criar no registrar de seu domínio os records tipo `NS`:

```
route53_delegation_set = {
  "id" = "N00862131AUK6YJ3OA5DF"
  "name_servers" = [
    "ns-1200.awsdns-22.org",
    "ns-1643.awsdns-13.co.uk",
    "ns-67.awsdns-08.com",
    "ns-931.awsdns-52.net",
  ]
}
```

Crie no registrar os quatro registros NS com o mesmo nome que a variável `zone_name` foi configurada e aguarde a "propagação" do registro. Com isso iremos efetivamente delegar a administração do subdomínio `devops-challenge.seudomínio.com` para a AWS para que possamos criar os certificados SSL e direcionar requisições para o CloudFront.

#### Deploy da infraestrutura - Production

Agora podemos criar a infraestrutura de produção. No workspace `production` execute um *run* manualmente, caso um não esteja esperando. Aguarde que o `plan` conclua com `Plan: 32 to add, 0 to change, 0 to destroy.` em seu resumo. Aplique o plan e aguarde a conclusão.

Essa etapa demorará entre 20 e 30 minutos para concluir, pois criará autoscaling groups, load balancers, ECS clusters, certificados IAM, CloudFront e Route53 Records. Houve um caso em que, num deploy do zero da infraestrutura, o terraform encontrou um problema com o provider. Na ocasião o provider havia gerado alguma inconsistência entre `plan` e `apply` e por via das dúvidas o terraform decidiu interromper o deploy da infraestrutura. Caso algo semelhante ocorra, apenas inicialize um novo run manualmente que a infraestrutura deverá subir normalmente.

### Ansible

Para realizar o deploy com o Ansible, copie o arquivo `production-vars.yml.dist` removendo a extensão `.dist`. Substitua o conteúdo do arquivo de acordo:

```yaml
---
ecr_repo_name: "backend"    # keep it like this
dockerfile_dir: "backend"   # keep it like this
backend_path: "api"         # keep it like this
aws_region: "us-east-2"
domain_name: "devops-challenge.seudomínio.com"
frontend_bucket: "seu-nome-devops-challenge-production-website"
```

Com isso, você precisa apenas de executar `ansible-playbook deploy.yml` que as roles do ansible cuidarão do processo de deploy.

### Conclusão da etapa em cloud

Terminado, visite `devops-challenge.seudomínio.com` e o todo deverá estar disponível. Observe que um arquivo chamado `default.json` será criado em `seu-nome-devops-challenge-production-state-storage`. Esse é o arquivo no qual o backend guarda o estado da sua aplicação TodoMVC.

# Documentação

## backend

| Variável de Ambiente | Significado | Default |
|--|--|--|
| STORAGE_BUCKET | Bucket S3 para guardar o estado. Guarda em disco caso for `None` | `None`|


- Rota `GET /api/state/{state_name}`
	- Code 200: Response Body `{"id": Number, "title": String, "completed": Bool}[]`
	- Code 404 se `{state_name}.json` não for encontrado ou se houver problema de credenciais. Body `{"cause":" String}` (`cause` é o motivo capturado do 404).
- Rota `PUT /api/state/{state_name}` Body: `{"id": Number, "title": String, "completed": Bool}[]`
	- Code 200: caso sucesso
	- Code 500: caso falha

## frontend

O frontend é o TodoMVC em Vue.js, como feito por Evan You. O `index.html` foi modificado para exibir `loading..` enquanto o backend responde com o estado salvo. O arquivo `store.js` foi modificado para, usando o [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API), comunicar com o backend.

## cloud-infrastrucuture (terraform)

### Network

A rede é composta por:

- VPC com CIDR `10.0.0.0/16`
- Duas *subnets* públicas para produção nas regiões us-east-2a e us-east-2b de CIDR `10.0.0.0/20` e `10.0.16.0/20` respectivamente.
- Duas *subnets* públicas para staging nas regiões us-east-2a e us-east-2b de CIDR `10.0.32.0/20` e `10.0.48.0/20` respectivamente.
- Duas *subnets* privadas nas regiões us-east-2a e us-east-2b de CIDR `10.0.64.0/20` e `10.0.80.0/20` respectivamente, para futuras implementações, como Lambda com acesso a VPC, RDS e banco de dados privativos por exemplo.
- Um EIP para o NAT Gateway.
- NAT Gateway para as subnets privadas, associado a *subnet* publica de produção da região A.
- Um Internet Gateway (IGW) para as subnets públicas.
- Uma rota para as redes públicas, mapeando `0.0.0.0/0` para o gateway padrão de internet.
- Uma rota para as redes privadas, mapeando `0.0.0.0/0` para o NAT gateway.
- Um subnet group com as redes privadas para posterior utilização em um RDS.


### website_bucket

Composto por:

- bucket S3 com a policy necessária para ser acessado pelo CloudFront, configuração de rota opcional e regras de CORS para o domínio solicitado.

### acm_certificate

- Recebe uma lista de `domain_names`. O primeiro domínio é utilizado como o `domain_name` do certificado. O restante é usado como `subject_alternative_names`
- Recebe também uma associação entre domain name e zone id `domain_name_by_zone_id`. O módulo itera sobre esse objeto e cruza com o output do certificado acm. Quando um certificado ACM é criado, ele gera também os recursos necessários para validação por DNS Challenge. Essas challenges precisam ser criadas por meio de Route53 Records nas zonas respectivas. O intuito desse argumento é abstrair esse mapa para que o usuário precise se preocupar apenas com os nomes e as zonas do certificado. Essa criação dos records é, no entanto opcional. Se um certificado necessitar ser criado em multiplas zonas, é necessário que apenas um módulo crie os DNS para a challenge. Os outros módulos precisam apenas validar os novos certificados nas novas zonas.
- Realiza a validação do certificado.

### ecs_definition

- Abstrai a criação de um serviço ECS
O ECS é muito flexível, porém igualmente complicado. No intuito de simplificar o processo de criação de múltiplos serviços, escrevi esse módulo que aproxima mais a interface de criação com o que vemos no `docker-compose`:

```js
module "ecs_service_backend" {
  source = "../ecs_definition"

  service_name      = "backend"
  cluster_id        = aws_ecs_cluster.default.id
  aws_region        = var.aws_region
  environment       = var.environment_name
  vpc_id            = data.terraform_remote_state.shared.outputs.network.vpc.id
  desired_count     = 2
  url               = var.domain_name
  lb_container_name = "backend"
  lb_container_port = 5000
  lb_listener       = module.load_balancer.https_listener
  load_balancer     = module.load_balancer.load_balancer
  task_role_arn     = module.iam_role_ecs_backend_task.role.arn
  health_check = {
    path    = "/status"
    matcher = 404
  }
  containers = [
    {
      name              = "backend"
      image             = aws_ecr_repository.backend.repository_url
      hard-memory-limit = 128
      soft-memory-limit = 64
      port-mappings = [
        {
          container-port = 5000
        }
      ]
      environment-variables = {
        STORAGE_BUCKET = aws_s3_bucket.state_storage.bucket
      }
    }
  ]
}
```
- Com esse módulo precisamos apenas passar o load balancer, porta de comunicação, nome da task principal do serviço, health check e informações dos containers que rodarão nesse serviço.

### environment

- É o módulo que define cada ambiente.
- Busca no estado do workspace *shared* as informações de rede e cria o Load Balancer em Muti AZ.
- Cria um Autoscaling Group, baseada na imagem Amazon Linux 2 ECS Optimized, que ao ser lançada se registra, por meio do `user_data.sh` no cluster ECS, também criado por ele.
- Cria dois certificados, um para o CloudFront, na região `us-east-1` e outro para o Load Balancer na zona configurada.
- Instancia o módulo do `ecs_definition`, que recebe as configurações do serviço `backend` e cria as devidas regras de redirecionamento para o target group do serviço ECS no Load Balancer. Tudo isso é feito de forma abstraída, sem que o usuário precise se preocupar com o formato da Task Definition, nem onde registrar o health check ou mesmo onde definir as regras de uso de recursos de sistema da EC2 Host.
- A Task Definition é compilada usando templates do Terraform. O formato recebido pela AWS é JSON para task definition, porém o arquivo é feito em YAML que possui uma sintaxe compatível com produção dinâmica de texto a partir de templates (JSON, por exemplo, requer que ao fim de uma lista não haja vírgula, o que dificulta o processo de criação de templates)

### iam_role
- Cria uma role com a trust relationship padrão para o EC2.
- Recebe uma lista de policies gerenciadas pela AWS e associa a Role.
- Recebe uma Policy JSON inline e cria uma policy inline para essa role.

### key_pair
- Cria uma chave TLS, cria uma keypair na AWS e armazena essa chave num bucket.

### load_balancer
- Abstrai a criação de um load balancer, com subnets, certificados e grupos de segurança passados por argumento, com um listener HTTP que redireciona para HTTPS e cria regras de redirecionamento de acordo com uma lista de regras passadas por argumento, por exemplo:

```js
module "private_load_balancer" {
  source = "./modules/load_balancer"

  name            = "private-load-balancer"
  security_groups = [module.security_group_internal_load_balancer.security_group.id]
  subnets         = module.vpc_prod.private_subnets
  internal        = true
  
  enable_deletion_protection = true
  https_listener_rules = [
    {
      action = {
        type             = "forward"
        target_group_arn = aws_lb_target_group.some_target_group.arn
      }
      conditions = [
        {
          type   = "host-header"
          values = ["backend.example.com"]
        },
        {
          type   = "path-pattern"
          values = ["api"]
        }
      ]
    }
  ]

  certificates = [
    aws_acm_certificate.cert_main.arn,
    module.acm_certificate_alternative.arn
  ]
}
```
Essa capacidade não foi necessária nesse projeto, mas o módulo é bem versátil.

## deploy (ansible)

### ecr
- Compila a imagem com a tag do ECR, segundo o nome configurado
- Loga no ECR da aws automaticamente
- Realiza *push* nessa imagem
- Elimina a imagem local

### frontend
- Instala dependencia NPM
- Envia os artefatos do frontend para o S3
- Realiza uma invalidação no cloudfront utilizando seu alias `devops-challenge.seu-domínio.com`

# Melhorias futuras

- Converter o ECS para Kubernetes

Apesar do ECS ser interessante para aplicações de docker na AWS, ele restringe o escopo de atuação, forçando o usuário a ficar nesse tipo de infraestrurua. Um trabalho grande precisa ser feito caso um port desse serviço seja necessário para outro tipo de infraestrutura.

- Usar uma database transacional ACID para o backend

Para o Intuito deste exercício é interessante essa abordagem de armazenamento no S3 por ser algo simples e fácil de configurar. Porém a abordagem de abandonar esquema abre portas para corrupção de dados. Outro problema seria a falta de suporte a multiplos usuários. Se mais de uma pessoa entrar na aplicação, ela se comportará de forma errática.

- Implementar uma autenticação OIDC para o frontend

- Criar um Jenkinsfile para pipeline programática do Jenkins

- Melhorar a documentação dos módulos do terraform
