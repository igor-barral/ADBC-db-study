"! ADBC (ABAP Database Connectivity) em ABAP clássico (on-premise).
"! Não é ABAP Cloud: CL_SQL_STATEMENT não é liberada para ABAP Cloud.
"! O exemplo lê a tabela T000 (mandantes), que existe em todo sistema.
CLASS zcl_ib_adbc_demo DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES:
      BEGIN OF ty_client,
        mandt TYPE c LENGTH 3,
        mtext TYPE c LENGTH 25,
      END OF ty_client,
      tt_client TYPE STANDARD TABLE OF ty_client WITH EMPTY KEY.

    METHODS read_clients
      IMPORTING iv_client         TYPE ty_client-mandt
      RETURNING VALUE(rt_clients) TYPE tt_client
      RAISING   cx_sql_exception.
ENDCLASS.


CLASS zcl_ib_adbc_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(clients) = read_clients( iv_client = sy-mandt ).
        out->write( clients ).
      CATCH cx_sql_exception INTO DATA(sql_error).
        out->write( sql_error->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_clients.
    " 1) O SQL é uma string enviada ao banco sem verificação do compilador ABAP.
    "    Nomes de tabela e coluna errados só aparecem em tempo de execução.
    "    O "?" é um parâmetro vinculado: nunca concatene entrada do usuário.
    DATA(sql) = NEW cl_sql_statement( ).
    DATA(client) = iv_client.
    sql->set_param( REF #( client ) ).

    DATA(result) = sql->execute_query(
      `SELECT mandt, mtext FROM t000 WHERE mandt = ?` ).

    " 2) O resultado é lido para uma tabela interna com a mesma ordem de colunas.
    result->set_param_table( REF #( rt_clients ) ).
    result->next_package( ).
    result->close( ).
  ENDMETHOD.

ENDCLASS.
