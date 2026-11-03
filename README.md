# ADBC - Study

> Nível: noção
> ABAP Database Connectivity: SQL nativo dinâmico a partir do ABAP, comum em código legado. Estudo de leitura, sem prática no trial de ABAP Cloud; contraste com [ABAP-SQL-db-study](https://github.com/igor-barral/ABAP-SQL-db-study) e [AMDP-db-study](https://github.com/igor-barral/AMDP-db-study).

## Objetivo

Reconhecer ADBC em código existente, entender o risco que ele traz e saber explicar por que o código novo usa ABAP SQL, CDS ou AMDP no lugar.

Ao concluir este estudo você deverá ser capaz de responder perguntas como:

- Por que o ADBC é evitado hoje?
- O que ele faz que o ABAP SQL não faz?
- Quais são as classes principais do ADBC?
- Como evitar SQL injection em ADBC?
- ADBC existe no ABAP Cloud?

## Ponte

| Você já conhece | No ADBC |
|---|---|
| PDO / `mysqli` com SQL em string | `CL_SQL_STATEMENT` com SQL em string |
| `$pdo->prepare('... WHERE id = ?')` + `bindValue` | `?` na string + `set_param( REF #( valor ) )` |
| `PDOStatement::fetchAll()` | `CL_SQL_RESULT_SET`: `set_param_table` + `next_package` |
| `PDOException` | `CX_SQL_EXCEPTION` |
| ADO.NET `SqlCommand` / JDBC `PreparedStatement` | Mesma ideia, mesmo tipo de risco |
| Query builder / Eloquent | ABAP SQL (verificado pelo compilador) |

## Conteúdo

### O que é

ADBC é uma API orientada a objetos para enviar SQL **nativo** do banco a partir do ABAP. O ABAP não interpreta a string: ela vai direto ao banco (no S/4HANA, o HANA). Classes principais:

| Classe | Papel |
|---|---|
| `CL_SQL_CONNECTION` | Conexão; `get_connection( ... )` abre uma conexão secundária configurada no sistema |
| `CL_SQL_STATEMENT` | Executa comandos: `execute_query`, `execute_update`, `execute_ddl` |
| `CL_SQL_RESULT_SET` | Resultado de uma consulta: `set_param_table`, `next_package`, `close` |
| `CX_SQL_EXCEPTION` | Erro de banco |

Existe também o SQL nativo estático antigo (`EXEC SQL ... ENDEXEC`), ainda mais antigo que o ADBC. Reconheça, mas não use.

### Exemplo do repositório

[src/zcl_ib_adbc_demo.clas.abap](src/zcl_ib_adbc_demo.clas.abap), ABAP clássico (`"version": "v757"` no abaplint):

```abap
DATA(sql) = NEW cl_sql_statement( ).
DATA(client) = iv_client.
sql->set_param( REF #( client ) ).

DATA(result) = sql->execute_query(
  `SELECT mandt, mtext FROM t000 WHERE mandt = ?` ).

result->set_param_table( REF #( rt_clients ) ).
result->next_package( ).
result->close( ).
```

O mesmo resultado em ABAP SQL, que é o que se escreve hoje:

```abap
SELECT mandt, mtext FROM t000 WHERE mandt = @iv_client INTO TABLE @rt_clients.
```

### Por que é evitado

| Aspecto | ABAP SQL | ADBC |
|---|---|---|
| Verificação em tempo de compilação | Sim (tabelas, campos, tipos) | Não: erro só em execução |
| Mandante | Automático | Manual (`WHERE mandt = ?`) |
| Portabilidade entre bancos | Sim | Não: SQL do banco específico |
| Buffer de tabelas SAP | Usado | Ignorado |
| Onde-usado, dependências, ATC | Completo | Limitado: a string é opaca |
| Risco de SQL injection | Baixo | Alto se a string for concatenada |
| ABAP Cloud | Permitido | Não liberado |

### O que ele faz que o ABAP SQL não faz

- executar SQL específico do banco que o ABAP SQL não expõe;
- DDL e comandos administrativos (`execute_ddl`);
- acessar outra base de dados por conexão secundária (`CL_SQL_CONNECTION=>get_connection`), incluindo tabelas que não existem no ABAP Dictionary;
- montar SQL totalmente dinâmico em tempo de execução (o ABAP SQL também aceita partes dinâmicas, com mais restrições).

Hoje, parte dessas necessidades é coberta por AMDP (SQLScript gerenciado pelo ABAP) e por ABAP SQL dinâmico.

### Segurança

Nunca concatene entrada do usuário na string SQL. Use `?` e `set_param`. Revisão de código e o ATC sinalizam SQL nativo como ponto de atenção; ver [ABAP-Test-Cockpit-softwarearchitecture-study](https://github.com/igor-barral/ABAP-Test-Cockpit-softwarearchitecture-study).

## Respostas

**Por que o ADBC é evitado hoje?**
Porque perde tudo o que o ABAP SQL oferece: verificação em compilação, mandante automático, buffer, portabilidade, rastreabilidade de dependências e proteção contra injeção. Além disso, não é liberado no ABAP Cloud.

**O que ele faz que o ABAP SQL não faz?**
Executa SQL nativo específico do banco, DDL, e acesso a bases secundárias e a tabelas fora do ABAP Dictionary.

**Quais são as classes principais?**
`CL_SQL_CONNECTION`, `CL_SQL_STATEMENT`, `CL_SQL_RESULT_SET` e a exceção `CX_SQL_EXCEPTION`.

**Como evitar SQL injection?**
Parâmetros vinculados com `?` e `set_param`, nunca concatenação de entrada externa.

**ADBC existe no ABAP Cloud?**
Não como API liberada. No ABAP Cloud, SQL nativo fica restrito a AMDP.

## Como rodar

1. Verificação local: `docker compose run --rm abaplint` seguido de `docker compose down`. Esperado: `0 issue(s)`. As classes `CL_SQL_*` não estão no pacote de dependências do abaplint, então as chamadas a elas não têm a assinatura verificada; apenas a sintaxe ABAP.
2. Execução real, opcional: só em sistema on-premise (ABAP Platform Trial), importando via abapGit no pacote `ZIB_ADBC` e executando `ZCL_IB_ADBC_DEMO` com F9 no ADT. No BTP ABAP Environment o código não ativa, por design.

## Referências

- ABAP Keyword Documentation, https://help.sap.com (buscar por "ADBC - ABAP Database Connectivity")
- SAP Community, https://community.sap.com (buscar por "CL_SQL_STATEMENT")
- abaplint, https://abaplint.org
