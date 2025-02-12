/*+ETLM {
depend:{
add:[
      {name:'custom_schema.subscription_data.membership_info'}   
     ,{name:'custom_schema.subscription_data.customer_details'}        
     ,{name:'custom_schema.subscription_data.marketplace_info'}   
     ,{name:'custom_schema.device_data.device_registration'}
     ]}
}*/

--- Tablet/Alexa/Kindle devices ---
drop table if exists device_metadata;
create temp table device_metadata as 
(
    SELECT DISTINCT     
            component_asin AS asin
          , component_device as device
    FROM custom_schema.device_data.device_asins
    WHERE TRUE
        AND UPPER(component_type) = 'DEVICE'
        AND UPPER(component_family) in ('TABLET','ALEXA','KINDLE')
        AND UPPER(item_name) NOT LIKE '%DEMO%'
        AND (item_name NOT ILIKE '%TEST%' OR item_name ILIKE '%LATEST%')
        AND UPPER(item_name) NOT LIKE '%DUMMY%'
);

-- Customers with a subscription
drop table if exists active_subscriptions;
create temp table active_subscriptions AS (
  SELECT distinct
        customer.customer_id

  FROM custom_schema.subscription_data.membership_info membership
      JOIN custom_schema.subscription_data.customer_details customer 
        ON customer.customer_key = membership.customer_key
      JOIN custom_schema.subscription_data.marketplace_info marketplace 
        ON membership.marketplace_key = marketplace.marketplace_key

  WHERE 1=1
     AND membership.lcl_first_stlm_date_key between '2024-01-01' and '2024-03-31'
     AND membership.lcl_cancel_date_key = 99991231
     AND marketplace = 'DE'
);


--- Customers who are registered in a Tablet/Alexa/Kindle ---
drop table if exists device_owners;
create temp table device_owners as
(
    select distinct
    	customer_id

    from custom_schema.device_data.device_registration reg
        inner join device_metadata 
            on upper(reg.device) = upper(device_metadata.device)
    
    where 1=1
        
        and date_trunc('day',reg.reg_date_utc) <= TO_DATE('{RUN_DATE_YYYYMMDD}','YYYYMMDD') 
        and nvl(reg.dereg_date_utc,'2199-01-01') >= TO_DATE('{RUN_DATE_YYYYMMDD}','YYYYMMDD')
        and reg.first_radio_on is not null
        and re.marketplace = 'DE'
);     


-- Tablet/Alexa/Kindle owners that do not have a subscription
select distinct
    dto.customer_id

from device_owners dto
    left join active_subscriptions subs
	    on subs.customer_id = dto.customer_id
where subs.customer_id is null;
