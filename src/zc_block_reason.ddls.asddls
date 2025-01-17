@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Block reason'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zc_block_reason
  as select from I_PaymentBlockingReasonText
{
  key PaymentBlockingReason,
      @Semantics.text: true
      PaymentBlockingReasonName
}

where
  Language = $session.system_language
