SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW  [Dev].[qa_key_check]
AS
With
field_check
As
(
SELECT 
'--- parent uprn check   ---' as qa_check_parent
,'CASCADES COURT, 13 -19HARTFIELD CRESCENT, WIMBLEDON, LONDON, SW19 3RL' as expected_parent_address
,addr2.address_string as actual_parent_address
, '--- child uprn check ---' as qa_check_child
,'FLAT 17, CASCADES COURT 13-19, HARTFIELD CRESCENT, LONDON, SW19 3RL' as expected_child_address
,addr.address_string as actual_child_address
,'48100401' as expected_child_uprn
,'TGL145577' as expected_title_number
,title.title_no As actual_title_number
,'Merton' as expected_LA
,oslauanm_current as actual_LA
,lease.[uprn] as  lr_lease_uprn
,title_bridge.uprn As lr_title_uprn
,prop_dim.uprn as child_uprn
,trans_fact.pp_uprn as trans_fact_uprn
,prop_dim.uprn as prop_dim_uprn
,geog.uprn as geog_uprn
,addr.uprn as addr_dim_uprn
,ac.uprn as household_uprn
FROM
 [DW_LandAndProperty].[dev].[tb_property_transaction_fact] trans_fact
LEFT JOIN [DW_LandAndProperty].[dev].[tb_calendar_dim] cal ON trans_fact.transaction_date_fk = cal.calendar_sk
LEFT JOIN [DW_LandAndProperty].[dev].[tb_property_transactions_dim] tran_dim ON trans_fact.transaction_attr_fk = tran_dim.transaction_attr_sk
-- prop dim
LEFT JOIN [DW_LandAndProperty].[dev].[tb_property_dim] prop_dim ON trans_fact.property_fk = prop_dim.property_sk
-- property attribute
LEFT JOIN [DW_LandAndProperty].[dev].[tb_property_attribute_dim] prop_attr ON prop_attr.property_attribute_sk = prop_dim.property_attribute_fk
-- geographic location
LEFT JOIN [DW_LandAndProperty].[dev].[tb_geographic_dim] geog ON prop_dim.geographic_fk = geog.geographic_sk
-- household (acorn)
LEFT JOIN  [DW_LandAndProperty].[dev].[tb_household_dim]  ac on prop_dim.household_fk = ac.household_sk
-- admin lookup
LEFT JOIN (select  pcds, oslauanm_current, rgnnm_current FROM  [DW_LandAndProperty].[dev].[tb_ONS_PostCode_Dim] WHERE Current_Row = 'Y') onspd ON onspd.pcds = prop_dim.postcode
--address
LEFT JOIN [DW_LandAndProperty].[dev].[tb_adp_address_dim] addr ON addr.address_sk = prop_dim.address_fk 
LEFT JOIN [DW_LandAndProperty].[dev].[tb_adp_address_dim] addr2 ON addr2.uprn = prop_dim.parent_uprn  and addr2.mailing_list_priority = 1
--leases
LEFT join [DW_LandAndProperty].[dev].[tb_property_lease_bridge] bridge on bridge.property_sk  = prop_dim.property_sk
LEFT join  [DW_LandAndProperty].[dev].[tb_property_lease_dim] lease on lease.lease_sk = bridge.lease_sk and lease.uprn_latest_lease = 1 
--Title & Owner
LEFT join [DW_LandAndProperty].[dev].[tb_property_title_bridge] title_bridge on title_bridge.property_sk  = prop_dim.property_sk  and title_no = 'TGL145577'
LEFT join  [DW_LandAndProperty].[dev].[tb_property_title_and_owner_dim] title on title.title_sk = title_bridge.title_sk
WHERE prop_dim.parent_uprn = 48100383 and prop_dim.uprn = 48100401
) select 
CASE WHEN expected_parent_address = actual_parent_address THEN 'Pass' ELSE 'Fail' END As parent_address_check
,CASE WHEN expected_child_address = actual_child_address  THEN 'Pass' ELSE 'Fail' END As child_address_check
,CASE WHEN expected_child_uprn = lr_lease_uprn AND
expected_child_uprn = lr_lease_uprn AND
expected_child_uprn = lr_title_uprn AND
expected_child_uprn =  child_uprn AND
expected_child_uprn =  trans_fact_uprn AND
expected_child_uprn =  prop_dim_uprn AND
expected_child_uprn =  geog_uprn AND
expected_child_uprn =  addr_dim_uprn AND
expected_child_uprn =  household_uprn  THEN 'Pass' ELSE 'Fail' END As child_uprn_check
,CASE WHEN expected_title_number = actual_title_number THEN 'Pass' ELSE 'Fail' END As child_title_check
,CASE WHEN expected_LA =  actual_LA THEN 'Pass' ELSE 'Fail' END As child_LA_check
,field_check.* from field_check;
GO
