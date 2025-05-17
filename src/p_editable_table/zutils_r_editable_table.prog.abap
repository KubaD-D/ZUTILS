REPORT ZUTILS_R_EDITABLE_TABLE.

PARAMETERS: p_tblnm TYPE dd02l-tabname.

DATA: go_container TYPE REF TO cl_gui_custom_container,
      go_grid      TYPE REF TO cl_gui_alv_grid,
      gt_fieldcat  TYPE lvc_t_fcat.

FIELD-SYMBOLS: <gt_table>          TYPE STANDARD TABLE,
               <gt_table_original> TYPE STANDARD TABLE.

START-OF-SELECTION.
  PERFORM load_data.
  PERFORM display_data.

FORM load_data.
  DATA: lt_data          TYPE REF TO data,
        lt_data_original TYPE REF TO data.

  CREATE DATA lt_data TYPE STANDARD TABLE OF (p_tblnm).
  CREATE DATA lt_data_original TYPE STANDARD TABLE OF (p_tblnm).
  ASSIGN lt_data->* TO <gt_table>.
  ASSIGN lt_data_original->* TO <gt_table_original>.

  SELECT * FROM (p_tblnm) INTO TABLE @<gt_table>.

  IF sy-subrc <> 0.
    WRITE: 'Data not found'.
    RETURN.
  ENDIF.

  <gt_table_original> = <gt_table>.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = p_tblnm
    CHANGING
      ct_fieldcat      = gt_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

   IF sy-subrc <> 0.
    WRITE: 'Error generating fieldcatalog'.
    RETURN.
  ENDIF.

  LOOP AT gt_fieldcat ASSIGNING FIELD-SYMBOL(<ls_fieldcat>).
    IF <ls_fieldcat>-key = abap_false.
      <ls_fieldcat>-edit = abap_true.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM display_data.
  go_container = NEW #( container_name = 'ALV_CONTAINER' ).
  go_grid = NEW #( i_parent = go_container ).

  go_grid->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_enter ).
  go_grid->set_ready_for_input( i_ready_for_input = 1 ).

  go_grid->set_table_for_first_display(
    EXPORTING
      i_structure_name = p_tblnm
    CHANGING
      it_outtab        = <gt_table>
      it_fieldcatalog  = gt_fieldcat
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4 ).

  CALL SCREEN 100.
ENDFORM.

FORM save_data.
  IF <gt_table> <> <gt_table_original>.
    MODIFY (p_tblnm) FROM TABLE <gt_table>.
  ENDIF.
ENDFORM.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'ZSTATUS'.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'CANCEL' OR 'EXIT'.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      PERFORM save_data.
  ENDCASE.
ENDMODULE.
