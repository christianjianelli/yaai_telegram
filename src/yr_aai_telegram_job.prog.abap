*&---------------------------------------------------------------------*
*& Report yr_aai_telegram_job
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT yr_aai_telegram_job.

PARAMETERS botname TYPE yde_aai_telegram_bot_name.

START-OF-SELECTION.

  DATA: task_id   TYPE yaai_async-id,
        task_name TYPE yaai_async-name.

  DATA(o_aai_telegram) = NEW ycl_aai_telegram( botname ).

  DATA(messages) = o_aai_telegram->get_updates( ).

  IF messages IS NOT INITIAL.

    DATA(lo_aai_async) = NEW ycl_aai_async( ).

    CASE o_aai_telegram->m_aai_api.

      WHEN yif_aai_const=>c_openai.

        IF o_aai_telegram->m_aai_chat_id IS INITIAL.

          o_aai_telegram->set_aai_chat_id( i_chat_id = NEW ycl_aai_db( i_api = yif_aai_const=>c_openai )->m_id ).

        ENDIF.

        task_name = |Telegram bot { botname }|.

        task_id = lo_aai_async->create(
          EXPORTING
            i_chat_id   = o_aai_telegram->m_aai_chat_id
            i_task_name = task_name
        ).

        DATA(response) = NEW ycl_aai_async_chat_openai( )->run(
          EXPORTING
            i_task_id  = task_id
            i_chat_id  = o_aai_telegram->m_aai_chat_id
            i_message  = messages
            i_agent_id = o_aai_telegram->m_aai_agent_id
        ).

    ENDCASE.

    o_aai_telegram->send_message( i_message = response ).

  ENDIF.
