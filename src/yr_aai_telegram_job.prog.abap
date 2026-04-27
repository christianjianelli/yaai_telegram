*&---------------------------------------------------------------------*
*& Report yr_aai_telegram_job
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT yr_aai_telegram_job.

PARAMETERS botname TYPE yde_aai_telegram_bot_name.

DATA: o_api TYPE REF TO object.

DATA: task_id    TYPE yaai_async-id,
      task_name  TYPE yaai_async-name,
      response   TYPE string,
      classname  TYPE seoclsname,
      methodname TYPE seocpdname VALUE 'RUN' ##NO_TEXT.

START-OF-SELECTION.

  DATA(o_aai_telegram) = NEW ycl_aai_telegram( botname ).

  DATA(messages) = o_aai_telegram->get_updates( ).

  IF messages IS NOT INITIAL.

    DATA(lo_aai_async) = NEW ycl_aai_async( ).

    CASE o_aai_telegram->m_aai_api.

      WHEN yif_aai_const=>c_openai.

        classname = 'YCL_AAI_ASYNC_CHAT_OPENAI'.

      WHEN yif_aai_const=>c_anthropic.

        classname = 'YCL_AAI_ASYNC_CHAT_ANTHROPIC'.

      WHEN yif_aai_const=>c_google.

        classname = 'YCL_AAI_ASYNC_CHAT_GOOGLE'.

      WHEN yif_aai_const=>c_mistral.

        classname = 'YCL_AAI_ASYNC_CHAT_OPENAI'.

      WHEN yif_aai_const=>c_ollama.

        classname = 'YCL_AAI_ASYNC_CHAT_OLLAMA'.

    ENDCASE.

    IF o_aai_telegram->m_aai_api IS NOT INITIAL.

      IF o_aai_telegram->m_aai_chat_id IS INITIAL.
        o_aai_telegram->set_aai_chat_id( i_chat_id = NEW ycl_aai_db( i_api = o_aai_telegram->m_aai_api )->m_id ).
      ENDIF.

      task_name = |Telegram bot { botname }|.

      task_id = lo_aai_async->create(
        EXPORTING
          i_chat_id   = o_aai_telegram->m_aai_chat_id
          i_task_name = task_name
      ).

      TRY.

          CREATE OBJECT o_api TYPE (classname).

        CATCH cx_sy_create_object_error.

      ENDTRY.

    ENDIF.

    IF o_api IS BOUND.

      TRY.

          CALL METHOD o_api->(methodname)
            EXPORTING
              i_task_id  = task_id
              i_chat_id  = o_aai_telegram->m_aai_chat_id
              i_message  = messages
              i_agent_id = o_aai_telegram->m_aai_agent_id
            RECEIVING
              r_response = response.

        CATCH cx_sy_dyn_call_illegal_class
              cx_sy_dyn_call_illegal_method
              cx_sy_dyn_call_illegal_type
              cx_sy_dyn_call_param_missing
              cx_sy_dyn_call_param_not_found
              cx_sy_dyn_call_excp_not_found
              cx_sy_ref_is_initial
              cx_sy_no_handler ##NO_HANDLER.
      ENDTRY.

    ENDIF.

    IF response IS NOT INITIAL.

      IF o_aai_telegram->send_message( i_message = response ) = abap_true.

        o_aai_telegram->set_messages_as_processed( ).

      ENDIF.

    ENDIF.

  ENDIF.
