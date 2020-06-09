# DevOps Challenge
Stack completa de infraestrutura e desenvolvimento de um website em Docker na AWS.

## Introdução

Este projeto tem o propósito de implementar uma aplicação composta de um Frontend estático e um Backend executado em [Docker](https://www.docker.com/) na nuvem.

Para a aplicação, foram feitas modificações no projeto do [TodoMVC Vue.js](http://todomvc.com/) para que o mesmo utilizasse um backend para salvar o estado das listas.

O Backend foi implementado em Python, utilizando o framework [Falcon](https://falcon.readthedocs.io/en/stable/). Para desenvolvimento, o estado é salvo em disco. Para produção, esse estado é salvo em um Bucket S3.

O Frontend é servido utilizando [S3](https://aws.amazon.com/s3/) + Cloudfront[Cloudfront](https://aws.amazon.com/cloudfront/), e o backend é executado utilizando o [Elastic Container Service](https://aws.amazon.com/ecs/) sobre [EC2](https://aws.amazon.com/ec2/) em múltiplas zonas de disponibilidade.

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

Para que o container do backend seja executado, optou-se por utilizar o Elastic Container Service. Nele, tarefas são definidas para executar imagens docker. Serviços, que são compostos por uma ou mais tarefas, se encarregam de delegar a execução deles a EC2 registradas no Cluster ECS ao qual pertence, e registrar as devidas portas no Load Balancer. O cluster é composto por duas EC2 em [regiões de disponibilidade](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/#Availability_Zones) distintas. Duas instâncias do nosso backend em dois containers separados rodam, dessa forma, em nessas duas EC2. Zonas de disponibilidades separadas são interessantes para reduzir a chance que uma indisponibilidade de serviço numa região possui de interromper o sistema em produçao.

O Elastic Container Service nos dá controle de quais permissões cada container herda, qual estratégia de deploy será empregada (Random, Distribuir por EC2, Distribuir por Zona...), qual proporção de recurso é dedicada para cada container, assim como toda a suite de configurações de um container como variáveis de ambiente, volumes etc...

As EC2 são controladas por um [Autoscaling Group](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html). O Autoscaling Group é capaz de definir as zonas de disponibilidades em que essas instancias serão lançadas, a quantidade de máquinas, o tipo e imagem a partir da qual essas máquinas serão lançadas, configurações internas (através do *user_data.sh*) e tipo de cobrança (on-demand ou spot). Para propósito desta demonstração serão lançadas instâncias tipo `t2.micro` que são inclusas no [free tier](https://aws.amazon.com/free/) da AWS.

O conteúdo estático do site (JavaScript, CSS e HTML) são servidos a partir de um bucket S3 por uma distribuição do Cloudfront. O Cloudfront é o serviço de distribuição de conteúdo da AWS. Ele é importante para aumentar a velocidade percebida do site, pois distribui o conteúdo a partir de pontos de presença [espalhados pelo globo](https://www.infrastructure.aws/).

Os certificados SSL são gerenciados pelo [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/) e não são retidos em nenhuma máquina que possa sofrer ataque a ter o conteúdo dos certificados vazados. A AWS se encarrega também da renovação e da disponibilidade desses certificados.

A infraestrutura utiliza o [Route 53](https://aws.amazon.com/route53/) para definição de DNS que faz referência a nossa distribuição do Cloudfront. Ela espera que um domínio exista e produz quatro [Name Servers](https://en.wikipedia.org/wiki/Name_server) que precisam ser associados a um domínio real por meio de records tipo NS para que, por exemplo, certificados SSL sejam gerados e que o site seja accessível.

A chave para acesso SSH das instâncias do cluster ECS é depositada automaticamente num bucket definido. No entanto, o ECS possui um painel de monitoramento bastante compreensivo, com eventos, métricas e logs que torna acesso direto por terminal às máquinas desnecessário.

Abaixo encontra-se um diagrama da topologia da infraestrutura em nuvem:

![](https://github.com/gchamon/devops-challenge/raw/master/docs/images/overview.jpg)

