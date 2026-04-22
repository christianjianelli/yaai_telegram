CLASS ycl_aai_telegram DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.
    INTERFACES yif_aai_telegram.

    ALIASES send_message FOR yif_aai_telegram~send_message.
    ALIASES get_updates FOR yif_aai_telegram~get_updates.

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA _o_client TYPE REF TO if_http_client.

    METHODS _create_connection
      IMPORTING
        i_url          TYPE string
        i_http_method  TYPE string DEFAULT 'GET'
        i_content_type TYPE string DEFAULT 'JSON'.

    METHODS _do_receive
      RETURNING VALUE(r_response) TYPE string.

    METHODS _get_token
      RETURNING VALUE(r_token) TYPE string.

    METHODS _get_chat_id
      RETURNING VALUE(r_token) TYPE string.

ENDCLASS.



CLASS ycl_aai_telegram IMPLEMENTATION.

  METHOD yif_aai_telegram~send_message.

    DATA: ls_response TYPE yif_aai_telegram~ty_send_message_response_s.

    DATA: l_url     TYPE string,
          l_token   TYPE string,
          l_chat_id TYPE string,
          l_json    TYPE string.

    CLEAR r_response.

    l_token = me->_get_token( ).

    l_chat_id = me->_get_chat_id( ).

    l_url = |{ yif_aai_telegram=>mc_base_url }/bot{ l_token }/sendMessage|.

    " Create HTTP client
    me->_create_connection(
      EXPORTING
        i_url         = l_url
        i_http_method = 'POST'
    ).

    " Prepare JSON body
    l_json = '{ "chat_id": "' && l_chat_id && '", "text": "' && i_message && '" }'.

    me->_o_client->request->set_cdata( l_json ).

    l_json = me->_do_receive( ).

    NEW ycl_aai_util( )->deserialize(
      EXPORTING
        i_json = l_json
      IMPORTING
        e_data = ls_response
    ).

    r_response = ls_response-result-text.

  ENDMETHOD.

  METHOD _create_connection.

    DATA l_content_type TYPE string.

    " Create HTTP client
    cl_http_client=>create_by_url(
      EXPORTING
        url = i_url
      IMPORTING
        client = me->_o_client
    ).

    me->_o_client->request->set_method( i_http_method ).

    CASE i_content_type.

      WHEN 'JSON'.

        l_content_type = 'application/json'.

    ENDCASE.

    IF l_content_type IS NOT INITIAL.
      me->_o_client->request->set_header_field( name = 'Content-Type' value = l_content_type ).
    ENDIF.

  ENDMETHOD.

  METHOD _do_receive.

    CLEAR r_response.

    " Send request
    me->_o_client->send(
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        http_invalid_timeout       = 4
        OTHERS                     = 5
    ).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    me->_o_client->receive(
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4
    ).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " Read response
    r_response = me->_o_client->response->get_cdata( ).

  ENDMETHOD.

  METHOD _get_token.

    CLEAR r_token.

    SELECT low FROM tvarvc
      WHERE name = 'TELEGRAM_BOT_TOKEN'
      INTO @r_token
      UP TO 1 ROWS.
    ENDSELECT.

  ENDMETHOD.

  METHOD _get_chat_id.

    CLEAR r_token.

    SELECT low FROM tvarvc
      WHERE name = 'TELEGRAM_BOT_CHAT_ID'
      INTO @r_token
      UP TO 1 ROWS.
    ENDSELECT.

  ENDMETHOD.

  METHOD yif_aai_telegram~get_updates.

    DATA: ls_response TYPE yif_aai_telegram~ty_get_updates_response_s.

    DATA: l_url     TYPE string,
          l_token   TYPE string,
          l_chat_id TYPE string,
          l_json    TYPE string.

    l_token = me->_get_token( ).

    l_chat_id = me->_get_chat_id( ).

    l_url = |{ yif_aai_telegram=>mc_base_url }/bot{ l_token }/getUpdates|.

    " Create HTTP client
    me->_create_connection( l_url ).

    l_json = me->_do_receive( ).

    NEW ycl_aai_util( )->deserialize(
      EXPORTING
        i_json = l_json
      IMPORTING
        e_data = ls_response
    ).

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_send_message) = abap_false.
    DATA(l_get_updates) = abap_true.

    CASE abap_true.

      WHEN l_send_message.

        l_response = me->send_message( i_message = 'Hey there!' ).

      WHEN l_get_updates.

        me->get_updates( ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
