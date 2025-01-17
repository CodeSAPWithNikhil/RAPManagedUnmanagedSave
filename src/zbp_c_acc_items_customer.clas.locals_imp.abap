CLASS lhc__accitems DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR _accitems RESULT result.
    METHODS validateblockreason FOR VALIDATE ON SAVE
      IMPORTING keys FOR _accitems~validateblockreason.
    METHODS releaseblock FOR MODIFY
      IMPORTING keys FOR ACTION _accitems~releaseblock RESULT result.

    METHODS setblock FOR MODIFY
      IMPORTING keys FOR ACTION _accitems~setblock RESULT result.

ENDCLASS.

CLASS lhc__accitems IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD validateblockreason.
    READ ENTITIES OF zc_acc_items_customer IN LOCAL MODE
    ENTITY _accitems FROM CORRESPONDING #( keys )
    RESULT DATA(ls_result).
    CHECK ls_result IS NOT INITIAL.
    DATA(lv_reason) = ls_result[ 1 ]-paymentblockingreason.
    SELECT SINGLE @abap_true FROM zc_block_reason
    WHERE paymentblockingreason = @lv_reason
    INTO @DATA(lv_exists).

    IF lv_exists = abap_false.
      APPEND CORRESPONDING #( keys[ 1 ] ) TO failed-_accitems ASSIGNING FIELD-SYMBOL(<fs_line>).
      <fs_line>-%update = if_abap_behv=>mk-on.

      APPEND CORRESPONDING #( keys[ 1 ] ) TO reported-_accitems ASSIGNING FIELD-SYMBOL(<fs_line2>).
      <fs_line2>-%update = if_abap_behv=>mk-on.
      <fs_line2>-%element-paymentblockingreason = if_abap_behv=>mk-on.
      <fs_line2>-%msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-error
        text     = 'Invalid blocking reason : ' && lv_reason
      ).
    ENDIF.

  ENDMETHOD.

  METHOD releaseblock.
    MODIFY ENTITIES OF zc_acc_items_customer IN LOCAL MODE
    ENTITY _accitems  UPDATE FIELDS ( paymentblockingreason )
    WITH VALUE #( FOR ls_keys IN keys ( %tky                  = ls_keys-%tky
                                        paymentblockingreason = space ) ).

    READ ENTITY IN LOCAL MODE zc_acc_items_customer
    FROM CORRESPONDING #( keys )
    RESULT DATA(lt_result).


    result  = VALUE #( FOR ls_result IN lt_result ( %tky   = ls_result-%tky
                                                    %param = ls_result ) ).
  ENDMETHOD.

  METHOD setblock.

    MODIFY ENTITIES OF zc_acc_items_customer IN LOCAL MODE
    ENTITY _accitems  UPDATE FIELDS ( paymentblockingreason )
    WITH VALUE #( FOR ls_keys IN keys ( %tky                  = ls_keys-%tky
                                        paymentblockingreason = 'A' ) ).

    READ ENTITY IN LOCAL MODE zc_acc_items_customer
    FROM CORRESPONDING #( keys )
    RESULT DATA(lt_result).


    result  = VALUE #( FOR ls_result IN lt_result ( %tky   = ls_result-%tky
                                                    %param = ls_result ) ).

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zc_acc_items_customer DEFINITION INHERITING FROM cl_abap_behavior_saver_failed.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_keys,
             bukrs TYPE bukrs,
             belnr TYPE belnr_d,
             gjahr TYPE gjahr,
             kunnr TYPE kunnr,
           END OF ty_keys.
    TYPES tt_accchg TYPE STANDARD TABLE OF accchg WITH EMPTY KEY.
    TYPES : ts_changed         TYPE STRUCTURE FOR CHANGE zc_acc_items_customer,
            tt_ddls_type_table TYPE HASHED TABLE OF  zc_acc_items_customer WITH UNIQUE KEY companycode accountingdocument fiscalyear,
            tt_changed         TYPE HASHED TABLE OF ts_changed WITH UNIQUE KEY companycode accountingdocument fiscalyear.

    TYPES: BEGIN OF MESH ty_cust_data_mesh,
             old_data TYPE tt_ddls_type_table ASSOCIATION _newdata TO new_data ON
                        companycode        =  companycode AND
                        accountingdocument =  accountingdocument AND
                        fiscalyear         = fiscalyear,
             new_data TYPE tt_changed ASSOCIATION _old_data TO old_data ON
                        companycode        =  companycode AND
                        accountingdocument =  accountingdocument AND
                        fiscalyear         = fiscalyear,
           END OF MESH ty_cust_data_mesh.
    CLASS-METHODS: change_doc
      IMPORTING is_keys   TYPE ty_keys
                it_accchg TYPE tt_accchg
      RETURNING VALUE(rc) TYPE sy-subrc.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zc_acc_items_customer IMPLEMENTATION.

  METHOD save_modified.
    DATA: lt_changed_fields TYPE tt_accchg.


    DATA ls_cust_data_mesh TYPE ty_cust_data_mesh.

    IF update-_accitems IS NOT INITIAL.

      ls_cust_data_mesh-new_data = CORRESPONDING #(  update-_accitems ).

      IF ls_cust_data_mesh-new_data IS NOT INITIAL.

        SELECT * FROM zc_acc_items_customer INTO CORRESPONDING FIELDS OF TABLE @ls_cust_data_mesh-old_data
        FOR ALL ENTRIES IN @ls_cust_data_mesh-new_data
        WHERE companycode        = @ls_cust_data_mesh-new_data-companycode
        AND   accountingdocument = @ls_cust_data_mesh-new_data-accountingdocument
        AND   fiscalyear         = @ls_cust_data_mesh-new_data-fiscalyear.

      ENDIF.
      "PaymentBlockingReason
      "AssignmentReference ZUONR
      "DocumentItemText SGTXT
      LOOP AT ls_cust_data_mesh-new_data INTO DATA(ls_acc).
        lt_changed_fields = VALUE #(  ).
        IF ls_acc-%control-paymentblockingreason = if_abap_behv=>mk-on.
          APPEND VALUE accchg( fdname = 'ZLSPR'
                               oldval = ls_cust_data_mesh-new_data\_old_data[ ls_acc ]-paymentblockingreason
                               newval = ls_acc-paymentblockingreason ) TO lt_changed_fields.
        ENDIF.
        IF ls_acc-%control-assignmentreference =  if_abap_behv=>mk-on.
          APPEND VALUE accchg( fdname = 'ZUONR'
                               oldval = ls_cust_data_mesh-new_data\_old_data[ ls_acc ]-assignmentreference
                               newval = ls_acc-assignmentreference ) TO lt_changed_fields.
        ENDIF.
        IF ls_acc-%control-documentitemtext =  if_abap_behv=>mk-on.
          APPEND VALUE accchg( fdname = 'SGTXT'
                               oldval = ls_cust_data_mesh-new_data\_old_data[ ls_acc ]-documentitemtext
                               newval = ls_acc-documentitemtext ) TO lt_changed_fields.
        ENDIF.
        IF lt_changed_fields IS NOT INITIAL.
          DATA(lv_rc) = change_doc( is_keys   = VALUE ty_keys( bukrs = ls_acc-companycode
                                                               belnr = ls_acc-accountingdocument
                                                               gjahr = ls_acc-fiscalyear
                                                               kunnr = ls_cust_data_mesh-new_data\_old_data[ ls_acc ]-customer )
                         it_accchg = lt_changed_fields ).
          IF  lv_rc <> 0.
            APPEND CORRESPONDING #( ls_acc ) TO failed-_accitems ASSIGNING FIELD-SYMBOL(<fs_line>).
            <fs_line>-%update = if_abap_behv=>mk-on.
          ENDIF.
          APPEND CORRESPONDING #( ls_acc ) TO reported-_accitems ASSIGNING FIELD-SYMBOL(<fs_line2>).
          <fs_line2>-%msg = new_message_with_text(
            severity = SWITCH #( lv_rc WHEN 0 THEN if_abap_behv_message=>severity-success ELSE if_abap_behv_message=>severity-error )
            text     = SWITCH #( lv_rc WHEN 0 THEN 'Updated Successfully' ELSE 'Update failed' ) ).
        ENDIF.

      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

  METHOD change_doc.

    DATA: lt_changed_helper TYPE TABLE OF accchg WITH DEFAULT KEY.
    lt_changed_helper = CORRESPONDING #( it_accchg ).
    CALL FUNCTION 'FI_DOCUMENT_CHANGE'
      EXPORTING
        i_kunnr              = is_keys-kunnr
        i_bukrs              = is_keys-bukrs
        i_belnr              = is_keys-belnr
        i_gjahr              = is_keys-gjahr
      TABLES
        t_accchg             = lt_changed_helper
      EXCEPTIONS
        no_reference         = 1
        no_document          = 2
        many_documents       = 3
        wrong_input          = 4
        overwrite_creditcard = 5
        OTHERS               = 6.

    RETURN sy-subrc.
  ENDMETHOD.

ENDCLASS.
