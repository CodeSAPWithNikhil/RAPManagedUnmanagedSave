@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer line items'
@Metadata.ignorePropagatedAnnotations: false
@UI.headerInfo:{typeName: 'Customer Accounting Item',
typeNamePlural: 'Customer Accounting Items',
    title: {
        type: #STANDARD,
        label: 'Accounting Document',
        value: 'AccountingDocument'
    }}
define root view entity zc_acc_items_customer
  as select distinct from I_OperationalAcctgDocItem as _AccDoc
  association [1] to zc_block_reason as _BlockText on _BlockText.PaymentBlockingReason = $projection.PaymentBlockingReason
{
      @UI.facet: [{  id: 'AccItem',
                   purpose: #STANDARD,
                   position: 10,
                   label: 'Customer Items',
                   type: #IDENTIFICATION_REFERENCE }]
      @UI:{ lineItem: [{ position: 10 }],
      identification: [{ position: 10 }]}
  key CompanyCode,
      @UI:{ lineItem: [{ position: 20 }],
      identification: [{ position: 20 }]}
  key AccountingDocument,
      @UI:{ lineItem: [{ position: 30 }],
      identification: [{ position: 30 }]}
  key FiscalYear,
      @UI:{ lineItem: [{ position: 40 }],
      identification: [{ position: 40 }],
      selectionField: [{ position: 10 }]}
      Customer,
      @UI:{ lineItem: [{ position: 50 }],
      identification: [{ position: 50 }],
      selectionField: [{ position: 20 }]}
      //      @Consumption: { valueHelpDefinition: [{ entity:{ element: 'PaymentBlockingReason', name: 'zc_block_reason'} }],
      //      filter: { multipleSelections: true, selectionType: #SINGLE } }
      @Consumption:{valueHelpDefinition: [{association: '_BlockText'}]}
      @ObjectModel.text.element: [ 'PaymentBlockingReasonName' ]
      _AccDoc.PaymentBlockingReason,

      @UI.hidden: true
      _BlockText.PaymentBlockingReasonName,

      @UI:{ lineItem: [{ position: 60 }],
      identification: [{ position: 60 }]}
      AssignmentReference,
      @UI:{ lineItem: [{ position: 70 }],
      identification: [{ position: 70 }]}
      DocumentItemText,
      @UI:{ lineItem: [{ position: 80 }],
      identification: [{ position: 80 }]}
      ClearingDate,
      @UI:{ lineItem: [{ position: 90 }],
      identification: [{ position: 90 }]}
      ClearingCreationDate,
      @UI:{
      lineItem: [{ position: 10},
      { type: #FOR_ACTION, dataAction: 'setBlock', label: 'Set Payment Block'},
      { type: #FOR_ACTION, dataAction: 'releaseBlock', label: 'Release Payment Block'}
      ],
      identification: [{ position: 10},
      {type: #FOR_ACTION, dataAction: 'setBlock', label: 'Set Payment Block'},
      { type: #FOR_ACTION, dataAction: 'releaseBlock', label: 'Release Payment Block'}
       ]
       }
      _BlockText

}
where
  Customer <> ''
