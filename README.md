# Agendamentos de Serviços

Esse projeto se trata de um aplicativo onde um Prestador (Barbeiro) poderá cadastrar o seu salão, onde os Clientes poderão reservar um horário para atendimento de acordo com a disponibilidade do Prestador. Ele foi criado a fim de atender a necessidade de um projeto Mobile com comunicação com API Rest da disciplina "Laboratório de Desenvolvimento para Dispositivos Móveis" do 5° Semestre do curso DSM - FATEC Franca.
<br>

## 📄 Descrição

O APP apresenta as seguintes fucionalidades:

### Todos os Tipos de Usuários

* Cadastrar/Logar: Para utilizar o APP, o usuário deve se cadastrar, informando algumas informações básicas para isso (Nome, E-mail e Telefone), podendo se cadastrar como Cliente ou Prestador (Barbeiro);

* Gerenciar Conta: Ambos os tipos de usuários poderão editar os seus dados informados durantes o cadastro, todos poderão ser editados, de acordo com as regras de cada um, exceto o Tipo (Cliente/Prestador) esse não poderá ser alterado. O mesmo também pode excluir a sua conta.

### Clientes:

* Iniciar Agendamento: O usuário sendo um Cliente, ele poderá iniciar um novo agendamento, escolhendo um Prestador (o APP recomendará o último escolhido e os já frequentados antes, bem como o usuário poderá pesquisar um pelo Nome ou Telefone), depois o mesmo escolherá os serviços disponíveis, podendo ser mais do que um, realizados pelo prestador selecionado, posteriormente poderá escolher um horário, também definido pelo Prestador de acordo com sua disponibilidade. Ao final poderá inserir alguma observação referente ao agendamento.

* Consultar Agendamentos Anteriores: O usuário poderá consultar os agendamentos que realizou anteriormente, com os seus dados (serviços realizados, preço, etc.).

### Prestador:

* Gerenciar Serviços: O Prestador pode cadastrar/alterar/inativar/excluir um serviço, informando os dados necessários para ele (Nome, Descrição e tempo Médio para Execução), informando também o preço, que é mantido um histórico de alterações, sendo possível para o Cliente poder visualizar esse histórico ou escolher esse serviço, se o mesmo não estiver inativo.

* Gerenciar Disponibilidade: O Prestador poderá gerenciar a sua disponibilidade dia após dia, informando os horários em que está disponível para o atendimento.

* Gerenciar Agendamentos: O Prestador pode gerenciar os agendamentos abertos pelos Clientes, a fim de se organizar, podendo excluí-los se desejar, enviando assim uma notificação ao Cliente.
<br>

## 📦 Aparência

### Tela de Login (Cliente, Prestador e Empresa)
<img src="/DOC/prints/login.png">
<br>

### Tela de Cadastro (Cliente, Prestador e Empresa)
<img src="/DOC/prints/cadastrar-se.png">
<br>

### Home (Cliente, Prestador e Empresa)
<img src="/DOC/prints/home.png">
<br>

### Perfil (Cliente, Prestador e Empresa)
<img src="/DOC/prints/perfil.png">
<br>

### Criar Agendamentos (Cliente)
<img src="/DOC/prints/criar-agendamento1.png">
<img src="/DOC/prints/criar-agendamento2.png">
<br>

### Histórico Agendamentos (Cliente)
<img src="/DOC/prints/historico.png">
<br>

### Perquisar Prestadores/Estabelcimentos/Empresas (Cliente)
<img src="/DOC/prints/pesquisa.png">
<br>

### Dashboard, Estabelecimentos, Serviços e Agendamentos (Empresa)
<img src="/DOC/prints/dashboard-estabelecimento-agendamento-servico-empresa.png">
<br>

### Dashboard, Serviços e Agendamentos (Prestador)
<img src="/DOC/prints/dashboard-agendamentos-prestador.png">
<br>

### Disponibilidade (Prestador)
<img src="/DOC/prints/disponibilidades-prestador.png">
<br>

## 🛠️ Construído com

Ferramentas:
* IntelliJ - Para a criação incial do APP em Flutter;
* Visual Studio Code - Editor de Código-Fonte;
* PostGreSQL - Sistema Gerenciador de Banco de Dados;
* Insomnia - Usado para os Testes do Back-End;
* Deepseek IA - Utilizado para ageração e correção de códigos;

Linguagens, Frameworks e API's:
* Dart - Linguagem de Programação (Mobile);
* Flutter - FrameWork de Dart;
* JavaScript - Linguagem de Programação (API);
* Node JS - Utilizado no Back-End, fazendo a conexão com o Banco de Dados;
* Prisma -  Para a conexão e gerenciamento das tabelas do BD;
* SQL - Linguagem do Banco de Dados;

## ✒️ Autores

* **[Cláudio de Melo Júnior](https://github.com/Claudio-Fatec)** — Criação das telas (Establishment e Availability);
* **[João Vitor Nicolau dos Santos](https://github.com/Joao-Vitor-Nicolau-dos-Santos)** — Criação das telas (Scheduling e SchedulingAttendant);
* **[Luís Pedro Dutra Carrocini](https://github.com/luis-pedro-dutra-carrocini)** — Criação da API/BD - Criação dos Services, Models e demais telas;
