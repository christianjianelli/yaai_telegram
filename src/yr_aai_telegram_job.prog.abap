*&---------------------------------------------------------------------*
*& Report yr_aai_telegram_job
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT yr_aai_telegram_job.

PARAMETERS botname TYPE yde_aai_telegram_bot_name.

START-OF-SELECTION.

  DATA(o_aai_telegram) = NEW ycl_aai_telegram( botname ).

  DATA(messages) = o_aai_telegram->get_updates( ).

  IF messages IS NOT INITIAL.

    DATA(lo_persistence) = NEW ycl_aai_db(
      i_api = yif_aai_const=>c_openai
      i_id = o_aai_telegram->m_aai_chat_id
    ).

    IF o_aai_telegram->m_aai_chat_id IS INITIAL.

      o_aai_telegram->set_aai_chat_id( i_chat_id = lo_persistence->m_id ).

    ENDIF.

    DATA(lo_aai_openai) = NEW ycl_aai_openai(
*      i_api                 =
*      i_model               =
*      i_use_completions     = abap_false
*      i_parallel_tool_calls = abap_true
*      i_safety_identifier   =
*      i_t_history           =
*      i_o_prompt            =
*      i_o_connection        =
       i_o_persistence       = lo_persistence
*      i_o_agent             =
    ).

    lo_aai_openai->chat(
      EXPORTING
*        id              =
        i_message       = messages
*        i_new           = abap_false
*        i_greeting      =
*        i_async_task_id =
*        i_o_prompt      =
*        i_o_agent       =
      IMPORTING
*        e_id            =
        e_response      = DATA(l_response)
*        e_failed        =
*        e_t_response    =
    ).

    o_aai_telegram->send_message( i_message = l_response ).

  ENDIF.
