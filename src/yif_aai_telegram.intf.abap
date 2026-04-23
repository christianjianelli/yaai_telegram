INTERFACE yif_aai_telegram
  PUBLIC.

  TYPES: BEGIN OF ty_entity_s,
           offset TYPE i,
           length TYPE i,
           type   TYPE string,
         END OF ty_entity_s.

  TYPES: ty_t_entity TYPE STANDARD TABLE OF ty_entity_s WITH EMPTY KEY.

  TYPES: BEGIN OF ty_from_s,
           id            TYPE i,
           is_bot        TYPE abap_bool,
           first_name    TYPE string,
           last_name     TYPE string,
           language_code TYPE string,
           username      TYPE string,
         END OF ty_from_s.

  TYPES: BEGIN OF ty_chat_s,
           id         TYPE i,
           first_name TYPE string,
           last_name  TYPE string,
           type       TYPE string,
         END OF ty_chat_s.

  TYPES: BEGIN OF ty_message,
           message_id TYPE i,
           from       TYPE ty_from_s,
           chat       TYPE ty_chat_s,
           date       TYPE i,
           text       TYPE string,
           entities   TYPE ty_t_entity,
         END OF ty_message.

  TYPES: BEGIN OF ty_result_s,
           update_id TYPE i,
           message   TYPE ty_message,
         END OF ty_result_s.

  TYPES: BEGIN OF ty_send_message_result_s,
           message_id TYPE i,
           from       TYPE ty_from_s,
           chat       TYPE ty_chat_s,
           date       TYPE int8,
           text       TYPE string,
         END OF ty_send_message_result_s.

  TYPES: ty_t_result TYPE STANDARD TABLE OF ty_result_s WITH EMPTY KEY.

  TYPES: BEGIN OF ty_get_updates_response_s,
           ok     TYPE abap_bool,
           result TYPE ty_t_result,
         END OF ty_get_updates_response_s.

  TYPES: BEGIN OF ty_send_message_response_s,
           ok     TYPE abap_bool,
           result TYPE ty_send_message_result_s,
         END OF ty_send_message_response_s.

  CONSTANTS mc_base_url TYPE string VALUE 'https://api.telegram.org' ##NO_TEXT.

  DATA: m_bot_name    TYPE yaai_telegram_b-name READ-ONLY,
        m_aai_chat_id TYPE yde_aai_chat_id READ-ONLY.

  METHODS get_updates
    RETURNING VALUE(r_messages) TYPE string.

  METHODS send_message
    IMPORTING
              i_message         TYPE csequence
    RETURNING VALUE(r_response) TYPE string.

  METHODS register_bot
    IMPORTING
              i_name           TYPE yde_aai_telegram_bot_name
              i_user           TYPE usnam
              i_description    TYPE yde_aai_telegram_bot_descr
              i_token          TYPE yde_aai_telegram_bot_token
              i_chat_id        TYPE yde_aai_telegram_chat_id
              i_agent_id       TYPE yde_aai_agent_id
    RETURNING VALUE(r_success) TYPE abap_bool.

  METHODS set_aai_chat_id
    IMPORTING
              i_chat_id        TYPE yde_aai_chat_id
    RETURNING VALUE(r_success) TYPE abap_bool.


ENDINTERFACE.
