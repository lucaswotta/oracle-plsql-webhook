# Case: Integração de Webhook com Oracle PL/SQL

Este repositório documenta a solução para um desafio real de negócio: a necessidade de criar um mecanismo de notificação em tempo real entre um sistema ERP Oracle e uma plataforma externa de chatbot. O código aqui se trata de uma versão anonimizada da implementada em produção.

## O Desafio

Em um ambiente de ERP com alto volume de transações, a equipe de um chatbot precisava ser notificada instantaneamente sobre mudanças no status dos pedidos de venda (ex: de "Em Análise" para "Liberado").

## A Solução Proposta

Para resolver este desafio, foi desenvolvida uma solução utilizando um **webhook** e recursos nativos do Oracle PL/SQL. Em vez de o sistema externo perguntar "algo mudou?", o próprio banco de dados agora **ativamente notifica** o sistema externo no exato momento em que uma alteração ocorra.

### Como Funciona

O fluxo é contido inteiramente dentro do banco de dados:
1.  **O Evento:** Um usuário do ERP atualiza o status de um pedido na tabela de vendas.
2.  **O Sensor (`TRIGGER`):** Uma trigger atrelada à tabela de pedidos, detecta essa mudança. Ela filtra a operação para garantir que apenas os pedidos relevantes (de uma empresa e segmento específicos, e cujo status realmente mudou) iniciem o processo.
3.  **A Lógica (`PACKAGE`):** A trigger aciona uma procedure dentro de um pacote PL/SQL dedicado. Este pacote encapsula toda a lógica:
    * Traduz os códigos de status internos (ex: 'L') para textos amigáveis (ex: 'LIBERADO').
    * Constrói uma mensagem de dados estruturada (JSON) contendo o status anterior e o novo, para dar mais contexto ao sistema externo.
    * Realiza a chamada HTTP POST para o endpoint do webhook, enviando a mensagem.
4.  **A Auditoria (`LOG TABLE`):** Cada tentativa de notificação, seja ela um sucesso ou uma falha, é registrada em uma tabela de log.
5.  **A Limpeza (`JOB`):** Periodicamente, um job agendado verifica a tabela de log e remove os registros antigos, garantindo a saúde do sistema a longo prazo.

## Boas Práticas

Durante o desenvolvimento foram adotadas boas práticas para garantir um código limpo e de fácil manutenção:
- **Nomenclatura:** Foi adotada uma convenção de nomenclatura clara (`p_` para parâmetros, `l_` para variáveis locais, `f_` para funções) para aumentar a legibilidade.
- **Robustez no Logging:** O uso de `PRAGMA AUTONOMOUS_TRANSACTION` no procedimento de log garante que falhas de rede nunca causem um `ROLLBACK` na operação do usuário do ERP.
- **Manutenção Automatizada:** A inclusão de um job (`DBMS_SCHEDULER`) para o expurgo automático de logs antigos, garantindo a performance sem intervenção manual.

## Estrutura

Os scripts de instalação estão organizados na pasta `install/` em uma ordem lógica de execução para facilitar o deploy:
- `01_create_table.sql`: Cria a tabela de log.
- `02_create_package.sql`: Cria a package com a lógica principal.
- `03_create_trigger.sql`: Cria a trigger que monitora os eventos.
- `04_create_maintenance_job.sql`: Cria um job para a limpeza periódica dos logs.

## Nota

Este projeto nasceu de uma necessidade de negócio real e representa uma solução que equilibra boas práticas com simplicidade, demonstrando como recursos nativos do **Oracle Database** podem ser usados para construir integrações eficientes.

---