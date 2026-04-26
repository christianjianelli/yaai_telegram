CLASS ycl_aai_telegram DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES yif_aai_telegram.

    ALIASES m_bot_name FOR yif_aai_telegram~m_bot_name.
    ALIASES m_aai_agent_id FOR yif_aai_telegram~m_aai_agent_id.
    ALIASES m_aai_chat_id FOR yif_aai_telegram~m_aai_chat_id.
    ALIASES m_aai_api FOR yif_aai_telegram~m_aai_api.

    ALIASES send_message FOR yif_aai_telegram~send_message.
    ALIASES get_updates FOR yif_aai_telegram~get_updates.
    ALIASES register_bot FOR yif_aai_telegram~register_bot.
    ALIASES set_aai_chat_id FOR yif_aai_telegram~set_aai_chat_id.

    METHODS constructor
      IMPORTING
        i_bot_name TYPE yaai_telegram_b-bot_name OPTIONAL.

    METHODS set_bot_name
      IMPORTING
        i_bot_name TYPE yaai_telegram_b-bot_name.


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
      RETURNING VALUE(r_chat_id) TYPE string.

    METHODS _load_aai_settings.

ENDCLASS.



CLASS ycl_aai_telegram IMPLEMENTATION.

  METHOD constructor.

    me->m_bot_name = i_bot_name.

    me->_load_aai_settings( ).

  ENDMETHOD.

  METHOD set_bot_name.

    me->m_bot_name = i_bot_name.

  ENDMETHOD.

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

    SELECT SINGLE token
      FROM yaai_telegram_b
      WHERE bot_name = @me->m_bot_name
        AND username = @sy-uname
        INTO @r_token.

  ENDMETHOD.

  METHOD _get_chat_id.

    CLEAR r_chat_id.

    SELECT SINGLE chat_id
      FROM yaai_telegram_b
      WHERE bot_name = @me->m_bot_name
        AND username = @sy-uname
        INTO @r_chat_id.

  ENDMETHOD.

  METHOD _load_aai_settings.

    IF me->m_bot_name IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE agent_id, api
      FROM yaai_telegram_b
      WHERE bot_name = @me->m_bot_name
        INTO ( @me->m_aai_agent_id, @me->m_aai_api ).

    SELECT SINGLE chat_id
      FROM yaai_telegram_c
      WHERE bot_name = @me->m_bot_name
        AND username = @sy-uname
       INTO @me->m_aai_chat_id.

  ENDMETHOD.

  METHOD yif_aai_telegram~get_updates.

    DATA: ls_response TYPE yif_aai_telegram~ty_get_updates_response_s.

    DATA: l_url     TYPE string,
          l_token   TYPE string,
          l_chat_id TYPE string,
          l_json    TYPE string,
          l_index   TYPE i,
          l_start   TYPE abap_bool.

    CLEAR r_messages.

    l_token = me->_get_token( ).

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

    SELECT MAX( message_id )
      FROM yaai_telegram_m
      WHERE bot_name = @me->m_bot_name
        AND username = @sy-uname
        INTO @DATA(l_last_message_id).

    l_index = 1.

    LOOP AT ls_response-result ASSIGNING FIELD-SYMBOL(<ls_result>).

      DATA(l_tabix) = sy-tabix.

      " Already processed?
      IF <ls_result>-message-message_id <= l_last_message_id.
        l_index = l_tabix.
        CONTINUE.
      ENDIF.

      " Bot start command
      IF <ls_result>-message-text = '/start'.
        l_index = l_tabix.
        l_start = abap_true.
        CONTINUE.
      ENDIF.

    ENDLOOP.

    IF l_start = abap_true.

      DELETE FROM yaai_telegram_m
          WHERE bot_name = @me->m_bot_name
            AND username = @sy-uname
            AND message_id <= @<ls_result>-message-message_id.

      MODIFY yaai_telegram_c FROM @( VALUE #( bot_name = me->m_bot_name
                                              username = sy-uname
                                              chat_id = space ) ).

      CLEAR me->m_aai_chat_id.

    ENDIF.

    LOOP AT ls_response-result ASSIGNING <ls_result> FROM l_index.

      " Bot start command
      IF <ls_result>-message-text = '/start'.
        CONTINUE.
      ENDIF.

      INSERT yaai_telegram_m FROM @( VALUE #( bot_name = me->m_bot_name
                                              username = sy-uname
                                              message_id = <ls_result>-message-message_id
                                              message_text = <ls_result>-message-text ) ).

      IF r_messages IS INITIAL.
        r_messages = <ls_result>-message-text.
      ELSE.
        r_messages = |{ r_messages }{ cl_abap_char_utilities=>newline }{ <ls_result>-message-text }|.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD yif_aai_telegram~register_bot.

    CLEAR r_success.

    INSERT yaai_telegram_b FROM @( VALUE #( bot_name = i_name
                                            username = i_user
                                            description = i_description
                                            token = i_token
                                            chat_id = i_chat_id
                                            agent_id = i_agent_id ) ).

    IF sy-subrc = 0.
      r_success = abap_true.
    ENDIF.

  ENDMETHOD.

  METHOD yif_aai_telegram~set_aai_chat_id.

    r_success = abap_false.

    IF me->m_bot_name IS INITIAL.
      RETURN.
    ENDIF.

    me->m_aai_chat_id = i_chat_id.

    MODIFY yaai_telegram_c FROM @( VALUE #( bot_name = me->m_bot_name
                                            username = sy-uname
                                            chat_id = i_chat_id ) ).

    r_success = abap_true.

  ENDMETHOD.

ENDCLASS.
